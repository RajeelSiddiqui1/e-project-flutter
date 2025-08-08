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
  late TextEditingController titleController;
  late TextEditingController detailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.category['title'] ?? '');
    detailController = TextEditingController(text: widget.category['detail'] ?? '');
  }

  @override
  void dispose() {
    titleController.dispose();
    detailController.dispose();
    super.dispose();
  }

  Future<void> updateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('categories').doc(widget.docId).update({
        'title': titleController.text.trim(),
        'detail': detailController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Category'),
        backgroundColor: Colors.teal,
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
                    Icon(Icons.edit, size: 80, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                        hintText: 'Enter title',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: detailController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Detail',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        hintText: 'Enter detail',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Detail is required' : null,
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updateCategory,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
