import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebaseproject/admin/category/categories.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? pickedImage;
  bool uploading = false;
  String? imageUrl;

  final String cloudName = 'dqjjreavg';
  final String apiKey = '369324225828725';
  final String apiSecret = 'RoDR867dtz2zKjYLgLoD7l_WkKE';

  @override
  void dispose() {
    titleController.dispose();
    detailController.dispose();
    super.dispose();
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
    if (imageFile.name.toLowerCase().endsWith('.png')) mimeType = 'image/png';
    else if (imageFile.name.toLowerCase().endsWith('.gif')) mimeType = 'image/gif';

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
        String uploadedUrl = jsonResponse['secure_url'];
        setState(() {
          uploading = false;
          imageUrl = uploadedUrl;
        });
        return uploadedUrl;
      } else {
        setState(() => uploading = false);
        Get.snackbar('Error', 'Image upload failed',
            backgroundColor: Colors.red, colorText: Colors.white);
        return null;
      }
    } catch (e) {
      setState(() => uploading = false);
      Get.snackbar('Error', 'Image upload error: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
      return null;
    }
  }

  Future<void> addCategory() async {
    if (!_formKey.currentState!.validate()) return;

    if (pickedImage == null) {
      Get.snackbar("Error", "Please select an image",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    try {
      final uploadedImageUrl = await uploadToCloudinary(pickedImage!);
      if (uploadedImageUrl == null) return;

      await FirebaseFirestore.instance.collection("categories").doc().set({
        "createdAt": DateTime.now(),
        "title": titleController.text.trim(),
        "detail": detailController.text.trim(),
        "imageUrl": uploadedImageUrl,
      });

      Get.offAll(() => const CategoriesScreen());
      Get.snackbar("Success", "Category added successfully",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Failed to add category",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.teal),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
      fillColor: Colors.grey.shade100,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
    );
  }

  Widget get imagePreview {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: pickedImage == null
            ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb
                    ? Image.network(pickedImage!.path, fit: BoxFit.cover)
                    : Image.file(File(pickedImage!.path), fit: BoxFit.cover),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Add Category"),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(Icons.category, size: 80),
                  const SizedBox(height: 20),
                  imagePreview,
                  const SizedBox(height: 10),
                  Text('Tap image to select',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 25),
                  TextFormField(
                    controller: titleController,
                    decoration: _inputDecoration("Title", Icons.title),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter title" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: detailController,
                    maxLines: 4,
                    decoration: _inputDecoration("Detail", Icons.description),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter detail" : null,
                  ),
                  const SizedBox(height: 30),
                  uploading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: addCategory,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                             
                              textStyle: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: const Text("Add Category"),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
