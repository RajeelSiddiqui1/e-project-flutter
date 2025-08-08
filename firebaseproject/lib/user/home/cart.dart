import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/user/home/checkout.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  Future<void> updateQuantity(String docId, int newQuantity, double price) async {
    if (newQuantity < 1) return;
    await _firestore.collection('cart').doc(docId).update({
      'quantity': newQuantity,
      'totalPrice': newQuantity * price,
    });
  }

  Future<void> removeItem(String docId) async {
    await _firestore.collection('cart').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to see your cart')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
         automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('cart')
            .where('userId', isEqualTo: user!.uid) // filter by userId
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          final cartItems = snapshot.data!.docs;

          double totalAmount = 0;
          for (var doc in cartItems) {
            final data = doc.data() as Map<String, dynamic>;
            totalAmount += (data['totalPrice'] ?? 0);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = cartItems[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final quantity = data['quantity'] ?? 1;
                    final price = (data['price'] ?? 0).toDouble();

                    return Card(
                      elevation: 3,
                      child: ListTile(
                        leading: (data['imagePath'] != null && data['imagePath'].isNotEmpty)
                            ? SizedBox(
                                width: 70,
                                height: 70,
                                child: Image.file(
                                  File(data['imagePath']),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 50),
                                ),
                              )
                            : const Icon(Icons.inventory, size: 50),
                        title: Text(data['name'] ?? 'No Name'),
                        subtitle: Text('\$${price.toString()} x $quantity'),
                        trailing: SizedBox(
                          width: 130,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                iconSize: 22,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  updateQuantity(doc.id, quantity - 1, price);
                                },
                              ),
                              SizedBox(
                                width: 24,
                                child: Center(
                                  child: Text(
                                    quantity.toString(),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              IconButton(
                                iconSize: 22,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  updateQuantity(doc.id, quantity + 1, price);
                                },
                              ),
                              IconButton(
                                iconSize: 22,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  removeItem(doc.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: \$${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: () {
                        Get.to(() => CheckoutScreen(amount: totalAmount));
                      },
                      child: const Text('Checkout'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
