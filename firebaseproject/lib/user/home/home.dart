import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/user/auth/login.dart';
import 'package:firebaseproject/user/home/cart_icon.dart';
import 'package:firebaseproject/user/home/product_detail.dart';
import 'package:firebaseproject/user/home/wish_list.dart';
import 'package:firebaseproject/user/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const ProfileScreen()),
            icon: const Icon(Icons.person_3_outlined),
          ),
          CartIconWithBadge(),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Get.to(() => const WishlistScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Get.offAll(() => const LoginScreen());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categories',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('categories')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No categories found.'));
                  }

                  final categories = snapshot.data!.docs;

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final category = categories[index].data() as Map<String, dynamic>;
                      final categoryId = categories[index].id;
                      final imagePath = category['imagePath'] as String?;
                      final title = category['title'] ?? 'No Title';

                      return GestureDetector(
                        onTap: () {
                          Get.to(() => CategoryProductsScreen(
                                categoryId: categoryId,
                                categoryTitle: title,
                              ));
                        },
                        child: Container(
                          width: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.teal.shade100,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imagePath != null && imagePath.isNotEmpty
                                    ? Image.file(
                                        File(imagePath),
                                        width: 90,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image, size: 50),
                                      )
                                    : const Icon(Icons.category, size: 70, color: Colors.teal),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                title,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Latest Products',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('products')
                    .orderBy('createdAt', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }

                  final products = snapshot.data!.docs;

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index].data() as Map<String, dynamic>;
                      final productId = products[index].id;
                      final imagePath = product['imagePath'] as String?;
                      final name = product['name'] ?? 'No Name';
                      final price = product['price'] ?? 0;
                      final discount = product['discount'] ?? 0;
                      final description = product['description'] ?? '';

                      String shortDescription = description.split(' ').length > 10
                          ? description.split(' ').sublist(0, 10).join(' ') + '...'
                          : description;

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imagePath != null && imagePath.isNotEmpty
                                      ? Image.file(
                                          File(imagePath),
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image, size: 50),
                                        )
                                      : const Icon(Icons.inventory, size: 50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              if (discount > 0)
                                Text('Discount: $discount%', style: const TextStyle(color: Colors.red)),
                              Text('\$${price.toString()}'),
                              const SizedBox(height: 4),
                              Text(
                                shortDescription,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.to(() => ProductDetailScreen(
                                            productId: productId,
                                            product: product,
                                          ));
                                    },
                                    child: const Text('Details'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(80, 35),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      if (user == null) {
                                        Get.snackbar('Error', 'Login required',
                                            backgroundColor: Colors.red, colorText: Colors.white);
                                        return;
                                      }
                                      await _firestore.collection('wishlist').add({
                                        'userId': user.uid,
                                        'productId': productId,
                                        'product': product,
                                        'addedAt': DateTime.now(),
                                      });
                                      Get.snackbar('Success', 'Added to wishlist',
                                          backgroundColor: Colors.green, colorText: Colors.white);
                                    },
                                    icon: const Icon(Icons.favorite_border),
                                    label: const Text('Wishlist'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(100, 35),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      backgroundColor: Colors.pinkAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class CategoryProductsScreen extends StatelessWidget {
  final String categoryId;
  final String categoryTitle;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('products')
            .where('categoryId', isEqualTo: categoryId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found in this category.'));
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              final imagePath = product['imagePath'] as String?;
              final name = product['name'] ?? 'No Name';
              final price = product['price'] ?? 0;
              final discount = product['discount'] ?? 0;
              final description = product['description'] ?? '';

              String shortDescription = description.split(' ').length > 10
                  ? description.split(' ').sublist(0, 10).join(' ') + '...'
                  : description;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imagePath != null && imagePath.isNotEmpty
                              ? Image.file(
                                  File(imagePath),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 50),
                                )
                              : const Icon(Icons.inventory, size: 50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (discount > 0)
                        Text('Discount: $discount%', style: const TextStyle(color: Colors.red)),
                      Text('\$${price.toString()}'),
                      const SizedBox(height: 4),
                      Text(
                        shortDescription,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Get.to(() => ProductDetailScreen(
                                    productId: productId,
                                    product: product,
                                  ));
                            },
                            child: const Text('Details'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(80, 35),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (user == null) {
                                Get.snackbar('Error', 'Login required',
                                    backgroundColor: Colors.red, colorText: Colors.white);
                                return;
                              }
                              await _firestore.collection('wishlist').add({
                                'userId': user.uid,
                                'productId': productId,
                                'product': product,
                                'addedAt': DateTime.now(),
                              });
                              Get.snackbar('Success', 'Added to wishlist',
                                  backgroundColor: Colors.green, colorText: Colors.white);
                            },
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('Wishlist'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(100, 35),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              backgroundColor: Colors.pinkAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


