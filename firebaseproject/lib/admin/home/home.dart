import 'package:firebaseproject/admin/category/auth/login.dart';
import 'package:firebaseproject/admin/category/categories.dart';
import 'package:firebaseproject/admin/product/products.dart';
import 'package:firebaseproject/admin/users/users.dart';
import 'package:firebaseproject/admin/orders/orders.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => const AdminLoginScreen());
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Welcome, Admin!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const CategoriesScreen()),
                  child: const Text("Manage Categories"),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const ProductsScreen()),
                  child: const Text("Manage Products"),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const UsersScreen()),
                  child: const Text("Manage Users"),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const OrdersScreen()),
                  child: const Text("Manage Orders"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
