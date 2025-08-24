import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:firebaseproject/user/chatbot/chatbot.dart';

class LikeManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> toggleLike(String reviewId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'Please sign in to like reviews',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return;
    }
    try {
      final likeQuery = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: user.uid)
          .where('reviewId', isEqualTo: reviewId)
          .limit(1)
          .get();
      if (likeQuery.docs.isNotEmpty) {
        await likeQuery.docs.first.reference.delete();
        Get.snackbar('Success', 'Review unliked',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
      } else {
        await _firestore.collection('likes').add({
          'userId': user.uid,
          'reviewId': reviewId,
          'createdAt': Timestamp.now(),
        });
        Get.snackbar('Success', 'Review liked',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update like: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    }
  }
}

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.product, required Map<String, dynamic> productData,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _userRating = 0;
  bool _ratingSubmitted = false;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _ratingsComments = [];
  double _averageRating = 0.0;
  bool _isLoading = true;
  Map<String, bool> _userLikes = {};
  final LikeManager _likeManager = LikeManager();

  @override
  void initState() {
    super.initState();
    _loadRatingsAndUserData();
  }

  Future<void> _loadRatingsAndUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('ratings')
          .where('productId', isEqualTo: widget.productId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      _ratingSubmitted = snapshot.docs.isNotEmpty;
    }
    final ratingsSnapshot = await _firestore
        .collection('ratings')
        .where('productId', isEqualTo: widget.productId)
        .get();
    final docs = ratingsSnapshot.docs;
    Map<String, bool> tempUserLikes = {};
    if (docs.isNotEmpty) {
      int totalRating = 0;
      List<Map<String, dynamic>> tempList = [];
      for (var doc in docs) {
        final data = doc.data();
        data['docId'] = doc.id;
        totalRating += ((data['rating'] is int)
            ? data['rating'] as int
            : (data['rating'] is double ? (data['rating'] as double).toInt() : 0));
        tempList.add(data);
        if (user != null) {
          final likeSnapshot = await _firestore
              .collection('likes')
              .where('userId', isEqualTo: user.uid)
              .where('reviewId', isEqualTo: doc.id)
              .limit(1)
              .get();
          tempUserLikes[doc.id] = likeSnapshot.docs.isNotEmpty;
        }
        final totalLikesSnapshot = await _firestore
            .collection('likes')
            .where('reviewId', isEqualTo: doc.id)
            .get();
        data['totalLikes'] = totalLikesSnapshot.docs.length;
      }
      setState(() {
        _ratingsComments = tempList;
        _averageRating = totalRating / docs.length;
        _userLikes = tempUserLikes;
      });
    } else {
      setState(() {
        _ratingsComments = [];
        _averageRating = 0.0;
        _userLikes = {};
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleLike(String reviewId) async {
    await _likeManager.toggleLike(reviewId);
    await _loadRatingsAndUserData();
  }

  Future<void> _submitRatingAndComment() async {
    if (_ratingSubmitted || _userRating == 0) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String firstName = "User";
    String lastName = "";
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      final nameParts = user.displayName!.split(" ");
      firstName = nameParts[0];
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";
    } else {
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        firstName = userDoc.data()?['firstName'] ?? "User";
        lastName = userDoc.data()?['lastName'] ?? "";
      }
    }
    try {
      await Get.dialog(
        AlertDialog(
          title: const Text('Confirm Rating'),
          content: const Text('Are you sure you want to submit this rating?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                final ratingsCollection = _firestore.collection('ratings');
                await ratingsCollection.add({
                  'userId': user.uid,
                  'productId': widget.productId,
                  'rating': _userRating,
                  'comment': _commentController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'userFirstName': firstName,
                  'userLastName': lastName,
                  'likeCount': 0,
                });
                setState(() {
                  _ratingSubmitted = true;
                  _commentController.clear();
                  _userRating = 0;
                });
                await _loadRatingsAndUserData();
                Get.snackbar('Success', 'Rating submitted', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit rating: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    }
  }

  Future<void> addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final cartCollection = _firestore.collection('cart');
      final cartItemQuery = await cartCollection
          .where('productId', isEqualTo: widget.productId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (cartItemQuery.docs.isNotEmpty) {
        final doc = cartItemQuery.docs.first;
        final currentQty = doc['quantity'] ?? 1;
        await cartCollection.doc(doc.id).update({
          'quantity': currentQty + quantity,
          'totalPrice': (currentQty + quantity) * (widget.product['price'] ?? 0),
        });
      } else {
        await cartCollection.add({
          'userId': user.uid,
          'productId': widget.productId,
          'name': widget.product['name'],
          'price': widget.product['price'],
          'quantity': quantity,
          'totalPrice': quantity * (widget.product['price'] ?? 0),
          'imageUrl': widget.product['imageUrl'] ?? '',
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar('Success', 'Added to cart', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add to cart: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    }
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 20,
      )),
    );
  }

  Widget _buildUserRatingStars() {
    return Row(
      children: List.generate(5, (i) => IconButton(
        icon: Icon(i < _userRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 30),
        onPressed: _ratingSubmitted ? null : () {
          setState(() => _userRating = i + 1);
        },
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = product['imageUrl'] as String?;
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product Detail', style: Theme.of(context).textTheme.titleLarge),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => setState(() => _loadRatingsAndUserData()),
            child: _isLoading
                ? const _ShimmerDetail()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (c, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                errorBuilder: (c, e, s) => const Icon(Icons.book_outlined, size: 100),
                              )
                            : const Icon(Icons.book_outlined, size: 100),
                      ).animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 16),
                      Text(
                        product['name'] ?? '',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildStars(_averageRating),
                      const SizedBox(height: 8),
                      Text(
                        'Price: \$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product['description'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                              ),
                              Text(quantity.toString(), style: Theme.of(context).textTheme.titleMedium),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setState(() => quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: addToCart,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Add to Cart'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Rate this product:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildUserRatingStars(),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        enabled: !_ratingSubmitted,
                        decoration: InputDecoration(
                          hintText: "Leave a comment (optional)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: _ratingSubmitted ? Colors.grey[200] : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _ratingSubmitted ? null : _submitRatingAndComment,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: _ratingSubmitted ? Colors.grey : null,
                        ),
                        child: Text(_ratingSubmitted ? 'Rated' : 'Submit Rating'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Reviews:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ..._ratingsComments.map((rc) => Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text((rc['userFirstName'] ?? 'U')[0],
                                style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(
                            "${rc['userFirstName'] ?? 'User'} ${rc['userLastName'] ?? ''}",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStars(rc['rating']?.toDouble() ?? 0),
                              if (rc['comment']?.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(rc['comment'] ?? '',
                                      style: Theme.of(context).textTheme.bodyMedium),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  rc['createdAt'] != null
                                      ? (rc['createdAt'] is Timestamp
                                          ? (rc['createdAt'] as Timestamp).toDate().toLocal().toString().substring(0, 19)
                                          : rc['createdAt'].toString())
                                      : '',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _userLikes[rc['docId']] ?? false 
                                            ? Icons.thumb_up 
                                            : Icons.thumb_up_outlined,
                                        color: _userLikes[rc['docId']] ?? false 
                                            ? Colors.blue 
                                            : Colors.grey,
                                      ),
                                      onPressed: () => _toggleLike(rc['docId']),
                                    ),
                                    Text(
                                      '${rc['totalLikes'] ?? 0}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
          ),
          const ChatBotFloating(),
        ],
      ),
    );
  }
}

class _ShimmerDetail extends StatelessWidget {
  const _ShimmerDetail();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 16),
        Container(width: double.infinity, height: 20, color: Colors.grey[300]),
        const SizedBox(height: 8),
        Container(width: 100, height: 20, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Container(width: double.infinity, height: 50, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Container(width: double.infinity, height: 100, color: Colors.grey[300]),
      ],
    );
  }
}
