import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        ),
        body: const Center(
          child: Text('Please log in to view your wishlist.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('wishlist')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading wishlist.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('Your wishlist is empty.'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final productId = data['productId'] as String? ?? 'Unknown';
              final createdAt = data['createdAt'] as Timestamp?;
              final addedDate = createdAt != null
                  ? createdAt.toDate().toString()
                  : 'Unknown date';

              // Assuming you might want to fetch product details from a 'products' collection.
              // For simplicity, this fetches the product name if a 'products' collection exists with a 'name' field.
              // If not needed, you can remove the FutureBuilder and just display productId.
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .get(),
                builder: (context, prodSnapshot) {
                  String productName = 'Product ID: $productId';
                  if (prodSnapshot.hasData && prodSnapshot.data!.exists) {
                    final prodData = prodSnapshot.data!.data() as Map<String, dynamic>?;
                    productName = prodData?['name'] as String? ?? productName;
                  }

                  return ListTile(
                    title: Text(productName),
                    subtitle: Text('Added at: $addedDate'),
                    // You can add more UI elements like images or remove buttons if needed.
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}