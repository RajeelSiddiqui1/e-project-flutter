import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/user/home/thanks_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckoutScreen extends StatefulWidget {
  final double amount;

  const CheckoutScreen({super.key, required this.amount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String deliveryOption = 'Pickup';
  String paymentMethod = 'Physical'; // Default Physical Payment
  double deliveryFee = 0;
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  double get totalAmount => widget.amount + deliveryFee;

  String generateRandomOrderId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> sendOrderConfirmationEmail(
      String email, String orderId, double amount, String deliveryOption) async {
    // TODO: Implement real email sending (e.g. Firebase Functions)
    print('Sending email to $email with Order ID: $orderId');
  }

  // New: Online payment form dialog
  Future<Map<String, dynamic>?> showOnlinePaymentForm() async {
    final _emailController = TextEditingController();
    final _cardNumberController = TextEditingController();
    final _expiryController = TextEditingController();
    final _cvvController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Online Payment'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email for receipt'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(labelText: 'Card Number'),
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  validator: (val) {
                    if (val == null || val.length != 16) return 'Enter 16-digit card number';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                  keyboardType: TextInputType.datetime,
                  maxLength: 5,
                  validator: (val) {
                    if (val == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(val)) return 'Enter valid MM/YY';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(labelText: 'CVV'),
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.length != 3) return 'Enter 3-digit CVV';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null), // Payment cancelled
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop({
                  'success': true,
                  'email': _emailController.text.trim(),
                });
              }
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  Future<void> placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return;
    }

    String receiptEmail = user.email ?? ''; // Default fallback

    if (paymentMethod == 'Online') {
      final paymentResult = await showOnlinePaymentForm();
      if (paymentResult == null || paymentResult['success'] != true) {
        Get.snackbar('Payment Failed', 'Online payment failed or cancelled',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
        return;
      }
      receiptEmail = paymentResult['email'];
    }

    setState(() => isLoading = true);

    final orderId = generateRandomOrderId();

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .get();

      final cartItems = cartSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'productId': data['productId'],
          'name': data['name'],
          'price': data['price'],
          'quantity': data['quantity'],
          'totalPrice': data['totalPrice'],
          'imagePath': data['imagePath'],
        };
      }).toList();

      await FirebaseFirestore.instance.collection('orders').add({
        'orderId': orderId,
        'userId': user.uid,
        'userEmail': receiptEmail, // use input email here
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': deliveryOption == 'Delivery' ? addressController.text.trim() : null,
        'deliveryOption': deliveryOption,
        'paymentMethod': paymentMethod,
        'itemsAmount': widget.amount,
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'orderDate': DateTime.now(),
        'status': 'Pending',
        'items': cartItems,
      });

      for (final doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      await sendOrderConfirmationEmail(
        receiptEmail,
        orderId,
        totalAmount,
        deliveryOption,
      );

      Get.snackbar('Success', 'Order placed! Tracking ID: $orderId',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);

      Navigator.pop(context);
      Get.offAll(() => const ThanksScreen());
    } catch (e) {
      Get.snackbar('Error', 'Failed to place order: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), 
       automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total items amount: \$${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      const Text('Delivery Option:', style: TextStyle(fontSize: 18)),
                      ListTile(
                        title: const Text('Pickup (No extra fee)'),
                        leading: Radio<String>(
                          value: 'Pickup',
                          groupValue: deliveryOption,
                          onChanged: (value) {
                            setState(() {
                              deliveryOption = value!;
                              deliveryFee = 0;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('Delivery (+ \$10)'),
                        leading: Radio<String>(
                          value: 'Delivery',
                          groupValue: deliveryOption,
                          onChanged: (value) {
                            setState(() {
                              deliveryOption = value!;
                              deliveryFee = 10;
                            });
                          },
                        ),
                      ),
                      const Divider(height: 30),
                      const Text('Payment Method:', style: TextStyle(fontSize: 18)),
                      ListTile(
                        title: const Text('Physical Payment'),
                        leading: Radio<String>(
                          value: 'Physical',
                          groupValue: paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              paymentMethod = value!;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('Online Payment'),
                        leading: Radio<String>(
                          value: 'Online',
                          groupValue: paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              paymentMethod = value!;
                            });
                          },
                        ),
                      ),
                      const Divider(height: 30),
                      Text('Total to pay: \$${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Divider(height: 40),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                        validator: (value) => value == null || value.isEmpty ? 'Enter your phone number' : null,
                      ),
                      const SizedBox(height: 15),
                      if (deliveryOption == 'Delivery')
                        TextFormField(
                          controller: addressController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Delivery Address'),
                          validator: (value) {
                            if (deliveryOption == 'Delivery' && (value == null || value.isEmpty)) {
                              return 'Enter your delivery address';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Place Order', style: TextStyle(fontSize: 18)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
