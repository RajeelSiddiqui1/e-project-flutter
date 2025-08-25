import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

 Future<void> resetPassword() async {
  final email = emailController.text.trim();

  if (email.isEmpty || !GetUtils.isEmail(email)) {
    Get.snackbar('Error', 'Please enter a valid email address.');
    return;
  }

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection("Users") // ✅ capital Users jaisa tumhara DB me hai
        .where('email', isEqualTo: email)
        .get();

    if (snapshot.docs.isEmpty) {
      Get.snackbar('Error', 'No account found with this email.');
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    Get.off(() => const ResetLinkSentScreen()); // ✅ Redirect
  } on FirebaseAuthException catch (e) {
    Get.snackbar('Error', e.message ?? 'Failed to send link.',
        snackPosition: SnackPosition.BOTTOM);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Enter your email and we will send you a password reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: resetPassword, child: const Text('Reset Password')),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ New Screen
class ResetLinkSentScreen extends StatelessWidget {
  const ResetLinkSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.mark_email_read_outlined,
                  size: 100, color: Colors.green),
              SizedBox(height: 20),
              Text(
                "Password reset link has been sent to your email.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
