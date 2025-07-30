import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/user/auth/login.dart';
import 'package:firebaseproject/user/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const ProfileScreen()),
            icon: const Icon(Icons.person_outline),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome Home!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(FirebaseAuth.instance.currentUser?.email ?? 'No email found'),
            
          ],
          
        ),
      ),
    );
  }
}
