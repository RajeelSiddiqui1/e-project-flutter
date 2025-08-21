import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Users"),
      automaticallyImplyLeading: false,),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Users Found"));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;

              // Debug print to check actual keys coming from Firebase
              print("User Data: $data");

              final firstName = data['firstname'] ?? data['firstName'] ?? '';
              final lastName  = data['lastname'] ?? data['lastName'] ?? '';
              final email     = data['email'] ?? data['userEmail'] ?? '';
              final age       = data['age']?.toString() ?? '';
              final phone     = data['phone'] ?? data['userPhone'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text("$firstName $lastName"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: $email"),
                      Text("Age: $age"),
                      Text("Phone: $phone"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
