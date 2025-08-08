import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product Detail'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text(
              product['name'] ?? '',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Price: \$${product['price']}",
              style: const TextStyle(fontSize: 18),
            ),
            if (product['discount'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  "Discount: ${product['discount']}%",
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              "Make: ${product['make'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              product['description'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
