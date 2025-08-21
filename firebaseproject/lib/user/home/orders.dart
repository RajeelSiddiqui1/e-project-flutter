import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        setState(() => _filteredOrders = List.from(_allOrders));
      } else {
        setState(() {
          _filteredOrders = _allOrders.where((order) {
            final items = order['items'] as List<dynamic>? ?? [];
            return items.any((item) =>
                (item['name'] as String).toLowerCase().contains(query));
          }).toList();
        });
      }
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _allOrders = [];
          _filteredOrders = [];
          _isLoading = false;
        });
        return;
      }
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true)
          .get();
      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
      setState(() {
        _allOrders = List<Map<String, dynamic>>.from(orders);
        _filteredOrders = List.from(_allOrders);
      });
    } catch (e) {
      setState(() {
        _allOrders = [];
        _filteredOrders = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? 'N/A';
    final status = order['status'] ?? 'Unknown';
    final totalAmount = order['totalAmount']?.toDouble() ?? 0.0;
    final orderDate = order['orderDate'] is Timestamp
        ? (order['orderDate'] as Timestamp).toDate()
        : DateTime.tryParse(order['orderDate']?.toString() ?? '') ?? DateTime.now();
    final items = order['items'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: ExpansionTile(
        title: Text('Order ID: $orderId', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Status: $status'),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Text('Order Date: ${orderDate.toLocal().toString().substring(0, 19)}'),
          const SizedBox(height: 8),
          ...items.map((item) {
            final name = item['name'] ?? 'Product';
            final qty = item['quantity'] ?? 1;
            final price = item['price']?.toDouble() ?? 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(name)),
                  Text('x$qty'),
                  const SizedBox(width: 8),
                  Text('\$${(price * qty).toStringAsFixed(2)}'),
                ],
              ),
            );
          }).toList(),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total: \$${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search orders by product name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? const Center(child: Text('No orders found'))
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return _buildOrderItem(order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
