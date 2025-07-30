import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/user/home/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signUpUser() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'uid': uid,
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'age': ageController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
      });

      Get.offAll(() => const HomeScreen());
    } on FirebaseAuthException catch (e) {
      log('Signup error: $e');
      Get.snackbar(
        'Signup Failed',
        e.message ?? 'An error occurred.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up'), 
           automaticallyImplyLeading: false,
      centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: firstNameController, decoration: const InputDecoration(hintText: 'First Name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 15),
              TextFormField(controller: lastNameController, decoration: const InputDecoration(hintText: 'Last Name', prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 15),
              TextFormField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => GetUtils.isEmail(v!) ? null : 'Invalid email'),
              const SizedBox(height: 15),
              TextFormField(controller: passwordController, obscureText: true, decoration: const InputDecoration(hintText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded)), validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
              const SizedBox(height: 15),
              TextFormField(controller: ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Age', prefixIcon: Icon(Icons.cake_outlined)), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 15),
              TextFormField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 25),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: signUpUser, child: const Text('Sign Up'))),
              TextButton(onPressed: () => Get.back(), child: const Text('Already have an account? Login')),
            ],
          ),
        ),
      ),
    );
  }
}