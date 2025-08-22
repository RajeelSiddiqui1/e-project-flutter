import 'package:flutter/material.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Get in Touch",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text("📧 Email: support@bookhaven.com", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("📞 Phone: +123 456 7890", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("🏢 Address: 123 Library Street, Book City", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
