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

  Future<void> addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategoryId == null) {
      Get.snackbar("Error", "Please select a category",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("products").add({
        "createdAt": DateTime.now(),
        "name": nameController.text.trim(),
        "price": double.tryParse(priceController.text.trim()) ?? 0,
        "description": descController.text.trim(),
        "make": makeController.text.trim(),
        "discount": discountController.text.trim().isNotEmpty
            ? double.tryParse(discountController.text.trim())
            : null,
        "categoryId": selectedCategoryId,
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
      appBar:
          AppBar(title: const Text("Add Product"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(Icons.add_box, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 30),

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
                decoration: _inputDecoration("Discount (optional)", Icons.percent),
              ),
              const SizedBox(height: 20),

              loadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: _inputDecoration("Select Category", Icons.category),
                      items: categories
                          .map<DropdownMenuItem<String>>((category) {
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

              SizedBox(
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
