import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebaseproject/admin/product/products.dart';

class EditProductScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> product;

  const EditProductScreen({
    super.key,
    required this.docId,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descController;
  late TextEditingController makeController;
  late TextEditingController discountController;

  String? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];

  dynamic pickedImage; // XFile for web, File for mobile
  bool uploading = false;

  final ImagePicker _picker = ImagePicker();

  // Cloudinary credentials (don't expose secret in real apps)
  final String cloudName = 'dqjjreavg';
  final String apiKey = '369324225828725';
  final String apiSecret = 'RoDR867dtz2zKjYLgLoD7l_WkKE';

  String? oldImageUrl;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product['name'] ?? '');
    priceController =
        TextEditingController(text: widget.product['price']?.toString() ?? '');
    descController = TextEditingController(text: widget.product['description'] ?? '');
    makeController = TextEditingController(text: widget.product['make'] ?? '');
    discountController =
        TextEditingController(text: widget.product['discount']?.toString() ?? '');

    selectedCategoryId = widget.product['categoryId'];
    oldImageUrl = widget.product['imageUrl'];
    fetchCategories();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descController.dispose();
    makeController.dispose();
    discountController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection("categories").get();
      setState(() {
        categories = snapshot.docs
            .map((doc) => {"id": doc.id, "title": doc["title"]})
            .toList();
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to load categories",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (kIsWeb) {
          pickedImage = image; // XFile on web
        } else {
          pickedImage = File(image.path); // File on mobile
        }
      });
    }
  }

  String generateSignature(Map<String, String> params) {
    var sortedKeys = params.keys.toList()..sort();
    var toSign = sortedKeys.map((key) => '$key=${params[key]}').join('&');
    var bytes = utf8.encode(toSign + apiSecret);
    var digest = sha1.convert(bytes);
    return digest.toString();
  }

  Future<String?> uploadToCloudinary(dynamic imageFile) async {
    setState(() => uploading = true);
    int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    Map<String, String> paramsToSign = {'timestamp': timestamp.toString()};
    String signature = generateSignature(paramsToSign);
    var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    var request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: imageFile.name));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    }

    request.fields['api_key'] = apiKey;
    request.fields['timestamp'] = timestamp.toString();
    request.fields['signature'] = signature;

    try {
      var response = await request.send();
      var resStr = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(resStr);
        String imageUrl = jsonResponse['secure_url'];
        setState(() => uploading = false);
        return imageUrl;
      } else {
        setState(() => uploading = false);
        Get.snackbar('Error', 'Cloudinary upload failed',
            backgroundColor: Colors.red, colorText: Colors.white);
        return null;
      }
    } catch (e) {
      setState(() => uploading = false);
      Get.snackbar('Error', 'Cloudinary upload error: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
      return null;
    }
  }

  Future<bool> deleteImageFromCloudinary(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      int uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1) return false;

      List<String> publicIdSegments = segments.sublist(uploadIndex + 2);
      String publicIdWithExtension = publicIdSegments.join('/');
      String publicId = publicIdWithExtension.split('.').first;

      final response = await http.post(
        Uri.parse('https://your-backend-api/delete-image'),
        body: {'publicId': publicId},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete image error: $e');
      return false;
    }
  }

  Future<void> updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategoryId == null) {
      Get.snackbar("Error", "Please select a category",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    String? newImageUrl = oldImageUrl;

    if (pickedImage != null) {
      final uploadedUrl = await uploadToCloudinary(pickedImage);
      if (uploadedUrl == null) {
        return;
      }
      if (oldImageUrl != null && oldImageUrl!.isNotEmpty) {
        await deleteImageFromCloudinary(oldImageUrl!);
      }
      newImageUrl = uploadedUrl;
    }

    double originalPrice = double.tryParse(priceController.text.trim()) ?? 0;
    double discountPercent = double.tryParse(discountController.text.trim()) ?? 0;
    double discountedPrice = originalPrice;
    if (discountPercent > 0) {
      discountedPrice = originalPrice - (originalPrice * (discountPercent / 100));
    }

    try {
      await FirebaseFirestore.instance.collection("products").doc(widget.docId).update({
        "name": nameController.text.trim(),
        "price": originalPrice,
        "discountedPrice": discountedPrice,
        "description": descController.text.trim(),
        "make": makeController.text.trim(),
        "discount": discountPercent,
        "categoryId": selectedCategoryId,
        "imageUrl": newImageUrl,
        "updatedAt": DateTime.now(),
      });

      Get.offAll(() => const ProductsScreen());
      Get.snackbar("Success", "Product updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Failed to update product",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> deleteProduct() async {
    try {
      if (oldImageUrl != null && oldImageUrl!.isNotEmpty) {
        await deleteImageFromCloudinary(oldImageUrl!);
      }
      await FirebaseFirestore.instance.collection('products').doc(widget.docId).delete();
      Get.offAll(() => const ProductsScreen());
      Get.snackbar('Deleted', 'Product deleted successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete product: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Widget get displayImage {
    if (pickedImage != null) {
      if (kIsWeb) {
        return Image.network(
          (pickedImage as XFile).path,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          pickedImage as File,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      }
    } else if (oldImageUrl != null && oldImageUrl!.isNotEmpty) {
      return Image.network(
        oldImageUrl!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        width: 150,
        height: 150,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, size: 50),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Product"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              Get.defaultDialog(
                title: 'Confirm Delete',
                middleText: 'Are you sure you want to delete this product?',
                onConfirm: () {
                  Navigator.of(context).pop();
                  deleteProduct();
                },
                onCancel: () {},
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: displayImage,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap image to change',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: "Product Name",
                  prefixIcon: Icon(Icons.inventory_2),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter product name" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Price",
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter price" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Description",
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter description" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: makeController,
                decoration: const InputDecoration(
                  hintText: "Make / Brand",
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter make or brand" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Discount (%)",
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                hint: const Text("Select Category"),
                items: categories.map<DropdownMenuItem<String>>((cat) {
                  return DropdownMenuItem<String>(
                    value: cat["id"] as String,
                    child: Text(cat["title"] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Select a category" : null,
              ),
              const SizedBox(height: 30),
              uploading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updateProduct,
                        child: const Text("Update Product"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}