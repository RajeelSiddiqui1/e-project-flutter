import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  Future<void> addCategory() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection("categories").doc().set({
        "createdAt": DateTime.now(),
        "title": titleController.text.trim(),
        "detail": detailController.text.trim(),
      });
      Get.offAll(() => const CategoriesScreen());
      Get.snackbar("Success", "Category added successfully",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Failed to add category",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Category"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(Icons.category, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 30),

              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: "Title",
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: detailController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Detail",
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? "Enter detail" : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: addCategory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text("Add Category"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
