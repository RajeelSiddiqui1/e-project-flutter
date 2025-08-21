import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'products.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descController = TextEditingController();
  final makeController = TextEditingController();
  final discountController = TextEditingController();

  String? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  bool loadingCategories = true;

  XFile? pickedImage;
  bool uploading = false;
  String? imageUrl;

  final ImagePicker _picker = ImagePicker();

  final String cloudName = 'dqjjreavg';
  final String apiKey = '369324225828725';
  final String apiSecret = 'RoDR867dtz2zKjYLgLoD7l_WkKE';

  @override
  void initState() {
    super.initState();
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
      final snapshot = await FirebaseFirestore.instance
          .collection("categories")
          .orderBy("title")
          .get();

      setState(() {
        categories = snapshot.docs
            .map((doc) => {"id": doc.id, "title": doc["title"]})
            .toList();
        loadingCategories = false;
      });
    } catch (e) {
      setState(() => loadingCategories = false);
      Get.snackbar("Error", "Failed to load categories",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        pickedImage = image;
        imageUrl = null;
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

  Future<String?> uploadToCloudinary(XFile imageFile) async {
    setState(() => uploading = true);

    int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    Map<String, String> paramsToSign = {'timestamp': timestamp.toString()};
    String signature = generateSignature(paramsToSign);

    var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    var request = http.MultipartRequest('POST', uri);

    final bytes = await imageFile.readAsBytes();

    String mimeType = 'image/jpeg';
    if (imageFile.name.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    } else if (imageFile.name.toLowerCase().endsWith('.gif')) {
      mimeType = 'image/gif';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: imageFile.name,
      contentType: MediaType.parse(mimeType),
    ));

    request.fields['api_key'] = apiKey;
    request.fields['timestamp'] = timestamp.toString();
    request.fields['signature'] = signature;

    try {
      var response = await request.send();
      var resStr = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(resStr);
        String imageUrl = jsonResponse['secure_url'];
        setState(() {
          uploading = false;
          this.imageUrl = imageUrl;
        });
        return imageUrl;
      } else {
        setState(() => uploading = false);
        return null;
      }
    } catch (e) {
      setState(() => uploading = false);
      return null;
    }
  }

  Future<void> addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategoryId == null) {
      Get.snackbar("Error", "Please select a category",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (pickedImage == null) {
      Get.snackbar("Error", "Please select an image",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      final uploadedImageUrl = await uploadToCloudinary(pickedImage!);
      if (uploadedImageUrl == null) {
        Get.snackbar("Error", "Image upload failed",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      double originalPrice = double.tryParse(priceController.text.trim()) ?? 0;
      double discountPercent = double.tryParse(discountController.text.trim()) ?? 0;
      double discountedPrice = originalPrice;
      if (discountPercent > 0) {
        discountedPrice = originalPrice - (originalPrice * (discountPercent / 100));
      }

      await FirebaseFirestore.instance.collection("products").add({
        "createdAt": DateTime.now(),
        "name": nameController.text.trim(),
        "price": originalPrice,
        "discountedPrice": discountedPrice,
        "description": descController.text.trim(),
        "make": makeController.text.trim(),
        "discount": discountPercent,
        "categoryId": selectedCategoryId,
        "imageUrl": uploadedImageUrl,
      });

      Get.offAll(() => const ProductsScreen());
      Get.snackbar(
        "Success",
        "Product added successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to add product",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product"),
          automaticallyImplyLeading: false,
          centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(Icons.add_box, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: pickImage,
                child: pickedImage == null
                    ? Container(
                        width: 150,
                        height: 150,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.camera_alt, size: 50),
                      )
                    : kIsWeb
                        ? Image.network(
                            pickedImage!.path,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(pickedImage!.path),
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration("Product Name", Icons.inventory_2),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter product name" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Price", Icons.attach_money),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter price" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: descController,
                maxLines: 3,
                decoration: _inputDecoration("Description", Icons.description),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter description" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: makeController,
                decoration: _inputDecoration("Make / Brand", Icons.business),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter make or brand" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Discount (%)", Icons.percent),
              ),
              const SizedBox(height: 20),
              loadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: _inputDecoration("Select Category", Icons.category),
                      items: categories.map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['id'].toString(),
                          child: Text(category['title'].toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? "Please select a category" : null,
                    ),
              const SizedBox(height: 30),
              uploading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: addProduct,
                        child: const Text("Add Product",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}