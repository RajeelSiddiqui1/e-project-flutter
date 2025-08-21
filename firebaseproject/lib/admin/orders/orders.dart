import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  void _updateStatus(String orderId, String newStatus) {
    FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Orders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Orders Found"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final items = (data['items'] as List<dynamic>?) ?? [];
              final orderId = orders[index].id;
              final status = data['status'] as String? ?? 'Pending';
              final name = data['name'] as String? ?? 'Unknown';
              final userEmail = data['userEmail'] as String? ?? 'No Email';
              final phone = data['phone'] as String? ?? 'No Phone';
              final address = data['address'] as String? ?? 'No Address';
              final paymentMethod = data['paymentMethod'] as String? ?? 'N/A';
              final deliveryOption = data['deliveryOption'] as String? ?? 'N/A';
              final deliveryFee = data['deliveryFee']?.toString() ?? '0';
              final itemsAmount = data['itemsAmount']?.toString() ?? '0';
              final totalAmount = data['totalAmount']?.toString() ?? '0';
              final orderDate = (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Items: ${items.length}"),
                      Text("Total: $totalAmount"),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      const Text("Status: "),
                      DropdownButton<String>(
                        value: status,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: "Pending", child: Text("Pending")),
                          DropdownMenuItem(value: "In Progress", child: Text("In Progress")),
                          DropdownMenuItem(value: "Completed", child: Text("Completed")),
                          DropdownMenuItem(value: "Rejected", child: Text("Rejected")),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _updateStatus(orderId, value);
                          }
                        },
                      ),
                    ],
                  ),
                  children: [
                    ListTile(
                      title: Text("Order ID: $orderId"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Name: $name"),
                          Text("Email: $userEmail"),
                          Text("Phone: $phone"),
                          Text("Address: $address"),
                          Text("Payment: $paymentMethod"),
                          Text("Delivery Option: $deliveryOption"),
                          Text("Delivery Fee: $deliveryFee"),
                          Text("Items Amount: $itemsAmount"),
                          Text("Order Date: $orderDate"),
                        ],
                      ),
                    ),
                    ...items.map((item) {
                      final itemName = item['name'] as String? ?? 'Unknown';
                      final price = item['price']?.toString() ?? '0';
                      final quantity = item['quantity']?.toString() ?? '0';
                      final totalPrice = item['totalPrice']?.toString() ?? '0';
                      final imageUrl = item['imageUrl'] as String? ?? '';

                      return ListTile(
                        leading: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(itemName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Price: $price"),
                            Text("Quantity: $quantity"),
                            Text("Total: $totalPrice"),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}