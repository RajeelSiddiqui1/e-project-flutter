// admin_home.dart

import 'package:firebaseproject/admin/category/auth/login.dart';
import 'package:firebaseproject/admin/category/categories.dart';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Welcome, Admin!'),
           TextButton(
                  onPressed: () => Get.to(() => const CategoriesScreen()),
                  child: const Text("Categories"),
                ),
          ],
        ),
      ),
    );
  }
}
