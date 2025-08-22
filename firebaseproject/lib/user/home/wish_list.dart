import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For shimmer effect
import 'package:get/get.dart';
import 'package:firebaseproject/user/home/product_detail.dart'; // Assuming this exists

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wishlist'),
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please log in to view your wishlist.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}), // Simple refresh to trigger rebuild
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('wishlist')
              .doc(user.uid)
              .collection('items')
              .orderBy('addedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading wishlist.'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ShimmerGrid(); // Shimmer effect while loading
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Your wishlist is empty.',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start adding your favorite books!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // At least 2 cards per row
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.7, // Adjusted for better fit
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final productId = data['productId'] as String? ?? 'Unknown';

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('products')
                      .doc(productId)
                      .get(),
                  builder: (context, prodSnapshot) {
                    if (!prodSnapshot.hasData || !prodSnapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    final prodData = prodSnapshot.data!.data() as Map<String, dynamic>;
                    final productName = prodData['name'] as String? ?? 'Unknown';
                    final imageUrl = prodData['imageUrl'] as String? ?? '';
                    final price = prodData['price'] as double? ?? 0.0;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(),
                      ),
                      child: InkWell(
                        onTap: () {
                          Get.to(() => ProductDetailScreen(
                                productId: productId,
                                product: prodData,
                              ));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: double.infinity,
                                          height: 130,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (c, child, p) => p == null
                                              ? child
                                              : const Center(
                                                  child:
                                                      CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                          errorBuilder: (c, e, s) => const Center(
                                              child: Icon(Icons.book_outlined, size: 50)),
                                        )
                                      : const Center(
                                          child: Icon(Icons.book_outlined, size: 50)),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('wishlist')
                                          .doc(user.uid)
                                          .collection('items')
                                          .doc(productId)
                                          .delete();
                                      Get.snackbar(
                                          'Removed', '$productName removed from wishlist');
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '\$${price.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms).scaleXY(begin: 0.95);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: 4, // Placeholder for shimmer effect
      itemBuilder: (context, index) => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(),
        ),
        child: Column(
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey[300],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 16, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Container(width: 60, height: 16, color: Colors.grey[300]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}