import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _getOrders() {
    User? user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("orders")
        .where("userId", isEqualTo: user.uid)
        .snapshots();
  }

  // Define status colors
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderItem(DocumentSnapshot order) {
    final items = order['items'] as List<dynamic>;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          "Order ID: ${order['orderId']}",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          "Amount: ${order['totalAmount']} \nDate: ${DateFormat.yMMMd().format((order['orderDate'] as Timestamp).toDate())}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Customer: ${order['name']}", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text("Email: ${order['userEmail']}", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text("Phone: ${order['phone']}", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text("Address: ${order['address']}", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text("Delivery: ${order['deliveryOption']}", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text("Delivery Fee: ${order['deliveryFee']}", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text("Payment: ${order['paymentMethod']}", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  "Status: ${order['status']}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getStatusColor(order['status']),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Date: ${DateFormat.yMMMd().add_jm().format((order['orderDate'] as Timestamp).toDate())}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text("Items:", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          item['imageUrl']?.isNotEmpty == true
                              ? Image.network(
                                  item['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                                )
                              : const Icon(Icons.image_not_supported, size: 50),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Name: ${item['name']}", style: Theme.of(context).textTheme.bodyMedium),
                                Text("Price: ${item['price']}", style: Theme.of(context).textTheme.bodyMedium),
                                Text("Quantity: ${item['quantity']}", style: Theme.of(context).textTheme.bodyMedium),
                                Text("Total: ${item['totalPrice']}", style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                Text("Items Total: ${order['itemsAmount']}", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  "Total Amount: ${order['totalAmount']}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Container(
            width: double.infinity,
            height: 16,
            color: Colors.grey[300],
          ),
          subtitle: Container(
            width: double.infinity,
            height: 12,
            color: Colors.grey[300],
            margin: const EdgeInsets.only(top: 8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: _getOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmer();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      "No orders found",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Place your first order to get started!",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            final orders = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: orders.length,
              itemBuilder: (context, index) => _buildOrderItem(orders[index]),
            );
          },
        ),
      ),
    );
  }
}