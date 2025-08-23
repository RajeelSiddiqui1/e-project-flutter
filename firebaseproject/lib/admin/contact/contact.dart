import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AdminOnlySubmissionsScreen extends StatelessWidget {
  const AdminOnlySubmissionsScreen({super.key});

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final adminDoc = await FirebaseFirestore.instance
        .collection('Admins')
        .doc(user.uid)
        .get();
    return adminDoc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!) {
          return Scaffold(
            appBar: AppBar(title: const Text("Access Denied")),
            body: const Center(child: Text("You do not have admin access.")),
          );
        }
        final stream = FirebaseFirestore.instance
            .collection('contacts')
            .where('deletedAt', isNull: true)
            .orderBy('timestamp', descending: true)
            .snapshots();
        return Scaffold(
          appBar: AppBar(
            title: const Text("Admin Submissions", style: TextStyle(fontFamily: 'Georgia')),
            automaticallyImplyLeading: false,
            elevation: 0,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print('Admin stream error: ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmerList();
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text("No Submissions Found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("All submitted requests will appear here."),
                    ],
                  ),
                );
              }
              print('Fetched ${snapshot.data!.docs.length} submissions for admin');
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _AdminSubmissionCard(doc: doc, data: data);
                },
              );
            },
          ),
        );
      },
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
                Container(width: 150, height: 20, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Container(width: double.infinity, height: 14, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Container(width: 200, height: 14, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Container(width: 100, height: 12, color: Colors.grey.shade300),
              ],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
      },
    );
  }
}

class _AdminSubmissionCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Map<String, dynamic> data;
  const _AdminSubmissionCard({required this.doc, required this.data});

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
    final status = data['status'] ?? 'Unknown';
    final userEmail = data['userEmail'] ?? 'No email provided';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
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
                DropdownButton<String>(
                  value: status,
                  items: ['Pending', 'In Progress', 'Resolved'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      doc.reference.update({'status': newValue});
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
            const SizedBox(height: 12),
            Text("User Email: $userEmail", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text("Submitted on: $date", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}