import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _userRating = 0; // user rating (1-5)
  bool _ratingSubmitted = false;
  final TextEditingController _commentController = TextEditingController();

  List<Map<String, dynamic>> _ratingsComments = [];
  double _averageRating = 0;

  Future<void> _loadRatings() async {
    final snapshot = await _firestore
        .collection('ratings')
        .where('productId', isEqualTo: widget.productId)
        .get();

    final docs = snapshot.docs;

    if (docs.isNotEmpty) {
      int totalRating = 0;
      List<Map<String, dynamic>> tempList = [];
      for (var doc in docs) {
        final data = doc.data();
        final ratingValue = data['rating'];
        totalRating += (ratingValue is int)
            ? ratingValue
            : (ratingValue is double ? ratingValue.toInt() : 0);
        tempList.add(data);
      }

      setState(() {
        _ratingsComments = tempList;
        _averageRating = totalRating / docs.length;
      });
    } else {
      setState(() {
        _ratingsComments = [];
        _averageRating = 0;
      });
    }
  }

  Future<void> _submitRatingAndComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'Please login to submit rating',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return;
    }
    if (_userRating == 0) {
      Get.snackbar('Error', 'Please select a rating',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return;
    }

    try {
      final ratingsCollection = _firestore.collection('ratings');

      final querySnapshot = await ratingsCollection
          .where('productId', isEqualTo: widget.productId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await ratingsCollection.doc(docId).update({
          'rating': _userRating,
          'comment': _commentController.text.trim(),
          'updatedAt': DateTime.now(),
        });
      } else {
        await ratingsCollection.add({
          'userId': user.uid,
          'productId': widget.productId,
          'rating': _userRating,
          'comment': _commentController.text.trim(),
          'createdAt': DateTime.now(),
          'userFirstName': user.displayName?.split(' ')[0] ?? 'User',
          'userLastName': user.displayName!.split(' ').length > 1
              ? user.displayName!.split(' ')[1]
              : '',
        });
      }

      setState(() {
        _ratingSubmitted = true;
        _commentController.clear();
        _userRating = 0;
      });

      await _loadRatings();

      Get.snackbar('Success', 'Rating and comment submitted',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit rating: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    }
  }

  Future<void> addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'You must be logged in to add to cart',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return;
    }

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
          'addedAt': DateTime.now(),
        });
      }

      Get.snackbar('Success', 'Added to cart',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add to cart: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Widget _buildAverageRatingStars(double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(Icon(
        i <= rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
      ));
    }
    return Row(children: stars);
  }

  Widget _buildUserRatingStars() {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(
        IconButton(
          icon: Icon(
            i <= _userRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 30,
          ),
          onPressed: () {
            setState(() {
              _userRating = i;
              _ratingSubmitted = false;
            });
          },
        ),
      );
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = product['imageUrl'] as String?;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(product['name'] ?? 'Product Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              SizedBox(
                height: 300,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 100),
                ),
              )
            else
              Container(
                height: 300,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.inventory, size: 100, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              product['name'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            Row(
              children: [
                const Text("Average Rating: ",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildAverageRatingStars(_averageRating),
                const SizedBox(width: 10),
                Text(_averageRating.toStringAsFixed(1)),
              ],
            ),

            const SizedBox(height: 10),
            Text("Price: \$${product['price']}"),
            if (product['discount'] != null)
              Text("Discount: ${product['discount']}%"),
            const SizedBox(height: 10),
            Text("Make: ${product['make']}"),
            const SizedBox(height: 20),
            Text(product['description'] ?? ''),
            const SizedBox(height: 30),

            Row(
              children: [
                const Text("Quantity: ", style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                ),
                Text(quantity.toString(), style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: addToCart,
              child: const Text("Add to Cart"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "Rate this product:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _buildUserRatingStars(),

            if (_userRating > 0) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Leave a comment (optional)',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _submitRatingAndComment,
                child: const Text("Submit Rating & Comment"),
              ),
            ],

            const SizedBox(height: 30),

            const Text(
              "Reviews & Comments:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_ratingsComments.isEmpty)
              const Text("No reviews yet. Be the first!"),

            for (var rc in _ratingsComments) ...[
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              'https://avatar.iran.liara.run/username?username=${rc['userId']}',
                            ),
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${rc['userFirstName'] ?? 'User'} ${rc['userLastName'] ?? ''}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildAverageRatingStars(rc['rating']?.toDouble() ?? 0),
                      const SizedBox(height: 6),
                      Text(
                        rc['comment'] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rc['createdAt'] != null
                            ? (rc['createdAt'] is Timestamp
                                ? (rc['createdAt'] as Timestamp)
                                    .toDate()
                                    .toLocal()
                                    .toString()
                                    .substring(0, 19)
                                : rc['createdAt'].toString())
                            : '',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
