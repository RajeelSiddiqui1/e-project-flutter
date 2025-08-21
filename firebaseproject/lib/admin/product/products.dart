import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebaseproject/admin/product/add_product.dart';
import 'package:firebaseproject/admin/product/edit_product.dart';
import 'package:firebaseproject/admin/product/product_detail.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String cloudName = 'dqjjreavg'; // your Cloudinary cloud name
  final String apiKey = '369324225828725'; // your Cloudinary api key
  final String apiSecret = 'RoDR867dtz2zKjYLgLoD7l_WkKE'; // your Cloudinary api secret

  // Generate signature for Cloudinary API
  String generateSignature(Map<String, String> params) {
    var sortedKeys = params.keys.toList()..sort();
    var toSign = sortedKeys.map((key) => '$key=${params[key]}').join('&');
    var bytes = utf8.encode(toSign + apiSecret);
    var digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Extract public ID from Cloudinary image URL
  String? extractPublicId(String imageUrl) {
    try {
      Uri uri = Uri.parse(imageUrl);
      List<String> segments = uri.pathSegments;
      int uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 1 >= segments.length) {
        return null;
      }
      List<String> publicIdSegments = segments.sublist(uploadIndex + 1);
      String full = publicIdSegments.join('/');
      int lastDot = full.lastIndexOf('.');
      if (lastDot != -1) {
        return full.substring(0, lastDot);
      }
      return full;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteImageFromCloudinary(String publicId) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    Map<String, String> params = {
      'public_id': publicId,
      'timestamp': timestamp.toString(),
    };
    String signature = generateSignature(params);

    var url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');

    var response = await http.post(url, body: {
      'public_id': publicId,
      'api_key': apiKey,
      'timestamp': timestamp.toString(),
      'signature': signature,
    });

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      if (jsonResponse['result'] == 'ok' || jsonResponse['result'] == 'not found') {
        return true;
      }
    }
    return false;
  }

  Future<void> _deleteProduct(String docId) async {
    try {
      final doc = await _firestore.collection('products').doc(docId).get();
      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found')),
          );
        }
        return;
      }

      final productData = doc.data()!;
      final imageUrl = productData['imageUrl'] as String?;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final publicId = extractPublicId(imageUrl);
        if (publicId != null) {
          bool imageDeleted = await deleteImageFromCloudinary(publicId);
          if (!imageDeleted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to delete image from Cloudinary')),
              );
            }
            return;
          }
        }
      }

      await _firestore.collection('products').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product: $e')),
        );
      }
    }
  }

  Future<String> _getCategoryName(String categoryId) async {
    try {
      final doc = await _firestore.collection('categories').doc(categoryId).get();
      return doc.exists ? (doc.data()?['title'] ?? '') : 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final product = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final imageUrl = product['imageUrl'] as String?;
              final categoryId = product['categoryId'] as String?;

              return FutureBuilder<String>(
                future: categoryId != null
                    ? _getCategoryName(categoryId)
                    : Future.value('Unknown'),
                builder: (context, catSnapshot) {
                  final categoryName = catSnapshot.data ?? 'Unknown';

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? Image.network(
                                imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 40),
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.inventory, size: 40),
                              ),
                      ),
                      title: Text(
                        product['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "Price: \$${product['price']}  •  Category: $categoryName",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditProductScreen(
                                  docId: docId,
                                  product: product,
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            _deleteProduct(docId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(product: product),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AddProductScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),
    );
  }
}