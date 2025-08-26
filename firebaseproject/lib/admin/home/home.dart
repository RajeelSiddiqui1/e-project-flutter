import 'package:firebaseproject/admin/auth/login.dart';
import 'package:firebaseproject/admin/category/categories.dart';
import 'package:firebaseproject/admin/contact/contact.dart';
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
    final options = [
      _AdminOption(
        title: "Manage Categories",
        icon: Icons.category_outlined,
        onTap: () => Get.to(() => const CategoriesScreen()),
      ),
      _AdminOption(
        title: "Manage Products",
        icon: Icons.inventory_2_outlined,
        onTap: () => Get.to(() => const ProductsScreen()),
      ),
      _AdminOption(
        title: "Manage Users",
        icon: Icons.people_alt_outlined,
        onTap: () => Get.to(() => const UsersScreen()),
      ),
      _AdminOption(
        title: "Manage Orders",
        icon: Icons.shopping_cart_outlined,
        onTap: () => Get.to(() => const OrdersScreen()),
      ),
      _AdminOption(
        title: "Manage User Contacts",
        icon: Icons.support_agent_outlined,
        onTap: () => Get.to(() => ContactsPage()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    ElevatedButton(
                      child: const Text("Logout"),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                Get.offAll(() => const AdminLoginScreen());
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Admin 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: options.map((opt) => _AdminCard(option: opt)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOption {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _AdminOption({required this.title, required this.icon, required this.onTap});
}

class _AdminCard extends StatelessWidget {
  final _AdminOption option;

  const _AdminCard({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: option.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, size: 40),
              const SizedBox(height: 12),
              Text(
                option.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
