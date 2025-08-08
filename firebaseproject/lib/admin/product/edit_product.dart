import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product['name'] ?? '');
    priceController = TextEditingController(text: widget.product['price']?.toString() ?? '');
    descController = TextEditingController(text: widget.product['description'] ?? '');
    makeController = TextEditingController(text: widget.product['make'] ?? '');
    discountController = TextEditingController(text: widget.product['discount']?.toString() ?? '');

    selectedCategoryId = widget.product['categoryId'];
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

  Future<void> updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    var name = nameController.text.trim();
    var price = priceController.text.trim();
    var desc = descController.text.trim();
    var make = makeController.text.trim();
    var discount = discountController.text.trim();

    if (selectedCategoryId == null) {
      Get.snackbar("Error", "Please select a category",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("products").doc(widget.docId).update({
        "name": name,
        "price": double.tryParse(price) ?? 0,
        "description": desc,
        "make": make,
        "discount": discount.isNotEmpty ? double.tryParse(discount) : null,
        "categoryId": selectedCategoryId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Product"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(
                Icons.edit_note,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 30),

              // Product Name
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

              // Price
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

              // Description
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

              // Make
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

              // Discount
              TextFormField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Discount (optional)",
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Category Dropdown
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

              SizedBox(
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
