import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/admin/category/auth/login.dart';
import 'package:firebaseproject/admin/home/home.dart';
import 'package:firebaseproject/user/auth/forgotpassword.dart';
import 'package:firebaseproject/user/auth/signup.dart';
import 'package:firebaseproject/user/home/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception("User ID not found");

      final adminDoc = await FirebaseFirestore.instance.collection("Admins").doc(uid).get();
      final userDoc = await FirebaseFirestore.instance.collection("Users").doc(uid).get();

      if (adminDoc.exists) {
        Get.offAll(() => const AdminHomeScreen());
      } else if (userDoc.exists) {
        Get.offAll(() => const HomeScreen());
      } else {
        Get.snackbar("Login Failed", "User not found in database.");
        FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      log('Login error: $e');
      Get.snackbar(
        'Login Failed',
        e.message ?? 'An unknown error occurred.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        automaticallyImplyLeading: false,
        centerTitle: true
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_open_rounded, size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 30),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (value) => (value == null || !GetUtils.isEmail(value)) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: loginUser, child: const Text('Login')),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Get.to(() => const ForgotPasswordScreen()),
                  child: const Text("Forgot Password?"),
                ),
                TextButton(
                  onPressed: () => Get.to(() => const SignupScreen()),
                  child: const Text("signup?"),
                ),
                TextButton(
                  onPressed: () => Get.to(() => const AdminLoginScreen()),
                  child: const Text("signup?"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
