import 'package:firebaseproject/user/home/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Adjust this import to your home screen file

class ThanksScreen extends StatelessWidget {
  const ThanksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        title: const Text('Thank You'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 100, ),
              const SizedBox(height: 20),
              const Text(
                'Thank you for your order!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Get.offAll(() => const HomeScreen());
                },
                child: const Text('Go to Home'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
