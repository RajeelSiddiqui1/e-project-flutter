import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:firebaseproject/user/chatbot/chatbot.dart'; // yahan import add kiya

class MySubmissionsScreen extends StatelessWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Submissions")),
        body: const Center(child: Text("Please log in to see your submissions.")),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('contacts')
        .where('userId', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Submissions", style: TextStyle(fontFamily: 'Georgia')),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerList();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 80),
                      SizedBox(height: 16),
                      Text("No Submissions Found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("Your submitted requests will appear here."),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _SubmissionCard(data: data, docId: doc.id);
                },
              );
            },
          ),

          const ChatBotFloating(), // yahan add kiya jaisy CartScreen me hai
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 20),
                const SizedBox(height: 12),
                Container(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                Container(width: 200, height: 14),
                const SizedBox(height: 12),
                Container(width: 100, height: 12),
              ],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
      },
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _SubmissionCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'];
    String date = "Date not available";
    if (timestamp is Timestamp) {
      date = DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());
    } else if (timestamp is String) {
      date = timestamp;
    }

    final reason = data['reason'] ?? 'No Reason';
    final message = data['message'] ?? 'No message content.';
    final status = (data['status'] ?? 'Pending').toString();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(reason, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(),
                  ),
                  child: Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Text("Submitted on: $date", style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('contacts').doc(docId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submission deleted")));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
