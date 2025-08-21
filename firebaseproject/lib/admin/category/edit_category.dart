import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebaseproject/admin/category/categories.dart';

class EditCategoryScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> category;

  const EditCategoryScreen({super.key, required this.docId, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController detailController;

  XFile? pickedImage;
  bool uploading = false;
  String? imageUrl; // This will store current or new image URL

  final ImagePicker _picker = ImagePicker();

  final String cloudName = 'dqjjreavg';
  final String apiKey = '369324225828725';
  final String apiSecret = 'RoDR867dtz2zKjYLgLoD7l_WkKE';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.category['title'] ?? '');
    detailController = TextEditingController(text: widget.category['detail'] ?? '');
    imageUrl = widget.category['imageUrl'] ?? null;
  }

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

  Future<void> updateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? newImageUrl = imageUrl;

    if (pickedImage != null) {
      final uploadedUrl = await uploadToCloudinary(pickedImage!);
      if (uploadedUrl == null) {
        setState(() => _isLoading = false);
        return; // Stop if upload failed
      }
      newImageUrl = uploadedUrl;
    }

    try {
      await FirebaseFirestore.instance.collection('categories').doc(widget.docId).update({
        'title': titleController.text.trim(),
        'detail': detailController.text.trim(),
        'imageUrl': newImageUrl,
        'createdAt': widget.category['createdAt'] ?? DateTime.now(),
      });

      Get.offAll(() => const CategoriesScreen());
      Get.snackbar("Success", "Category updated successfully",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Failed to update category",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget get imagePreview {
    if (pickedImage != null) {
      if (kIsWeb) {
        return Image.network(
          pickedImage!.path,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          File(pickedImage!.path),
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      }
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 50),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      return Container(
        width: 150,
        height: 150,
        color: Colors.grey.shade300,
        child: const Icon(Icons.camera_alt, size: 50),
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
      appBar: AppBar(
        title: const Text('Edit Category'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imagePreview,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap image to change',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 30),

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
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: updateCategory,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              child: const Text('Update Category'),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
