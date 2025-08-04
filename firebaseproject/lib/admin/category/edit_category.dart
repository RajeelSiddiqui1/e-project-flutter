import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebaseproject/admin/category/categories.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditCategoryScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> category;

  const EditCategoryScreen({super.key, required this.docId, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.category['title'] ?? '';
    detailController.text = widget.category['detail'] ?? '';
  }

  @override
  void dispose() {
    titleController.dispose();
    detailController.dispose();
    super.dispose();
  }

  void updateCategory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        'title': titleController.text.trim(),
        'detail': detailController.text.trim(),
        'createdAt': widget.category['createdAt'] ?? DateTime.now(),
      };

      await FirebaseFirestore.instance.collection('categories').doc(widget.docId).update(data);
      Get.to(() => const CategoriesScreen());
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Category'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue[800],
        elevation: 4,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Category Details',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        hintText: 'Enter title',
                      ),
                      validator: (value) => value!.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: detailController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Detail',
                        border: OutlineInputBorder(),
                        hintText: 'Enter detail',
                      ),
                      validator: (value) => value!.isEmpty ? 'Detail is required' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updateCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
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