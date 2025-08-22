import 'package:firebaseproject/admin/category/auth/login.dart';
import 'package:firebaseproject/user/auth/forgotpassword.dart';
import 'package:firebaseproject/user/auth/signup.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  Future<void> loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception("User ID not found");

      final userDoc = await FirebaseFirestore.instance.collection("Users").doc(uid).get();
      if (userDoc.exists) {
        Get.offAll(() => const HomeScreen());
      } else {
        Get.snackbar("Login Failed", "User not found in database");
        _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Login Failed", e.message ?? 'Unknown error', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final UserCredential userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
      final user = userCredential.user;
      if (user == null) throw Exception("Google sign in failed");

      final userDoc = FirebaseFirestore.instance.collection("Users").doc(user.uid);
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        final emailQuery = await FirebaseFirestore.instance
            .collection("Users")
            .where("email", isEqualTo: user.email)
            .get();

        if (emailQuery.docs.isEmpty) {
          await userDoc.set({
            "name": user.displayName ?? "User",
            "email": user.email,
            "createdAt": DateTime.now(),
          });
        }
      }

      Get.offAll(() => const HomeScreen());
    } catch (e) {
      Get.snackbar("Google Sign-In Failed", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login"), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(Icons.lock_open_rounded, size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 30),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                  validator: (value) => (value == null || !GetUtils.isEmail(value)) ? "Enter valid email" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? "Password must be 6+ chars" : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: loginWithEmail, child: const Text("Login")),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loginWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text("Sign in with Google"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(onPressed: () => Get.to(() => const ForgotPasswordScreen()), child: const Text("Forgot Password?")),
                TextButton(onPressed: () => Get.to(() => const SignupScreen()), child: const Text("Signup")),
                TextButton(onPressed: () => Get.to(() => const AdminLoginScreen()), child: const Text("login admin")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}