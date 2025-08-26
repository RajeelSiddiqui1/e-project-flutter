import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String productId;

  const ProductDetailScreen({super.key, required this.product, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _ratingsComments = [];
  double _averageRating = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    setState(() => _isLoading = true);

    final ratingsSnapshot = await _firestore
        .collection('ratings')
        .where('productId', isEqualTo: widget.productId)
        .get();

    final docs = ratingsSnapshot.docs;
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
      }
      setState(() {
        _ratingsComments = tempList;
        _averageRating = totalRating / docs.length;
      });
    } else {
      setState(() {
        _ratingsComments = [];
        _averageRating = 0.0;
      });
    }
    setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.product['imageUrl'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name'] ?? 'Product Detail'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: _isLoading
          ? const _ShimmerDetail()
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 100),
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 20),
                  Text(
                    widget.product['name'] ?? '',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStars(_averageRating),
                  const SizedBox(height: 12),
                  Text(
                    "Price: \$${widget.product['price']?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (widget.product['discount'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        "Discount: ${widget.product['discount']}%",
                        style: const TextStyle(fontSize: 18, color: Colors.green),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    "Make: ${widget.product['make'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.product['description'] ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Reviews:',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStars(rc['rating']?.toDouble() ?? 0),
                          if (rc['comment']?.isNotEmpty ?? false)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                rc['comment'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              rc['createdAt'] != null
                                  ? (rc['createdAt'] is Timestamp
                                      ? (rc['createdAt'] as Timestamp).toDate().toLocal().toString().substring(0, 19)
                                      : rc['createdAt'].toString())
                                  : '',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.thumb_up, color: Colors.blue, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '${rc['likeCount'] ?? 0} Likes',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.thumb_down, color: Colors.red, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '${rc['unlikeCount'] ?? 0} Unlikes',
                                  style: const TextStyle(fontSize: 14),
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
    );
  }
}

class _ShimmerDetail extends StatelessWidget {
  const _ShimmerDetail();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 20),
        Container(width: double.infinity, height: 26, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Container(width: 100, height: 18, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Container(width: 80, height: 18, color: Colors.grey[300]),
        const SizedBox(height: 20),
        Container(width: double.infinity, height: 50, color: Colors.grey[300]),
      ],
    );
  }
}