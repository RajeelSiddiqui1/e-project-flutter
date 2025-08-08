import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: const Center(child: Text('Please login to see your wishlist.')),
      );
    }

    final wishlistStream = _firestore
        .collection('wishlist')
        .where('userId', isEqualTo: user.uid)
        .orderBy('addedAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: wishlistStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading wishlist:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Your wishlist is empty.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final product = Map<String, dynamic>.from(data['product'] ?? {});
              final productId = data['productId'] ?? '';

              final name = product['name'] ?? 'No Name';
              final price = product['price']?.toString() ?? '0';
              final discount = product['discount']?.toString() ?? '0';
              final description = product['description']?.toString() ?? '';
              final words = description.split(' ');
              final shortDesc = words.length > 10
                  ? '${words.take(10).join(' ')}...'
                  : description;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.inventory, size: 50),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (discount != '0')
                        Text('Discount: $discount%',
                            style: const TextStyle(color: Colors.red)),
                      Text('\$$price'),
                      Text(
                        shortDesc,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      try {
                        await doc.reference.delete();
                        Get.snackbar('Removed', 'Product removed from wishlist',
                            backgroundColor: Colors.green,
                            colorText: Colors.white);
                      } catch (e) {
                        Get.snackbar('Error', 'Failed to remove product',
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                      }
                    },
                  ),
                  onTap: () {
                    if (productId.isNotEmpty) {
                      /* Navigate to your ProductDetailScreen */
                      // Get.to(() => ProductDetailScreen(
                      //       productId: productId,
                      //       product: product,
                      //     ));
                    } else {
                      Get.snackbar('Error', 'Product details not available',
                          backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}