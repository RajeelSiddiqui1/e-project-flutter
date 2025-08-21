import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/user/home/thanks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class CheckoutScreen extends StatefulWidget {
  final double amount;
  const CheckoutScreen({super.key, required this.amount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum CheckoutStatus { idle, processing, success }

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  String deliveryOption = 'Pickup';
  String paymentMethod = 'Physical';
  double deliveryFee = 0;
  CheckoutStatus _status = CheckoutStatus.idle;

  double get totalAmount => widget.amount + deliveryFee;

  Future<void> placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return;
    }
    String receiptEmail = user.email ?? '';
    if (paymentMethod == 'Online') {
      final paymentResult = await _showOnlinePaymentForm();
      if (paymentResult == null || paymentResult['success'] != true) {
        Get.snackbar('Payment Failed', 'Online payment failed or cancelled.');
        return;
      }
      receiptEmail = paymentResult['email'];
    }
    setState(() => _status = CheckoutStatus.processing);
    try {
      final orderId = _generateRandomOrderId();
      final cartSnapshot = await FirebaseFirestore.instance.collection('cart').where('userId', isEqualTo: user.uid).get();
      final cartItems = cartSnapshot.docs.map((doc) => doc.data()).toList();
      await FirebaseFirestore.instance.collection('orders').add({
        'orderId': orderId,
        'userId': user.uid,
        'userEmail': receiptEmail,
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': deliveryOption == 'Delivery' ? addressController.text.trim() : 'Store Pickup',
        'deliveryOption': deliveryOption,
        'paymentMethod': paymentMethod,
        'itemsAmount': widget.amount,
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'orderDate': Timestamp.now(),
        'status': 'Pending',
        'items': cartItems,
      });
      for (final doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }
      setState(() => _status = CheckoutStatus.success);
      await Future.delayed(const Duration(seconds: 2));
      Get.offAll(() => const ThanksScreen());
    } catch (e) {
      Get.snackbar('Error', 'Failed to place order: $e');
      setState(() => _status = CheckoutStatus.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Order')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: '1. Delivery Method',
                    child: Column(
                      children: [
                        _OptionCard(
                          title: 'Store Pickup',
                          subtitle: 'Collect from our Karachi location.',
                          icon: Icons.store_mall_directory_outlined,
                          isSelected: deliveryOption == 'Pickup',
                          onTap: () => setState(() {
                            deliveryOption = 'Pickup';
                            deliveryFee = 0;
                          }),
                        ),
                        const SizedBox(height: 12),
                        _OptionCard(
                          title: 'Home Delivery',
                          subtitle: 'Delivered to your doorstep for \$10.00.',
                          icon: Icons.local_shipping_outlined,
                          isSelected: deliveryOption == 'Delivery',
                          onTap: () => setState(() {
                            deliveryOption = 'Delivery';
                            deliveryFee = 10;
                          }),
                        ),
                      ],
                    ),
                  ),
                  _buildSectionCard(
                    title: '2. Payment Method',
                    child: Column(
                      children: [
                        _OptionCard(
                          title: 'Cash on Delivery',
                          subtitle: 'Pay with cash upon receiving your order.',
                          icon: Icons.money_outlined,
                          isSelected: paymentMethod == 'Physical',
                          onTap: () => setState(() => paymentMethod = 'Physical'),
                        ),
                        const SizedBox(height: 12),
                        _OptionCard(
                          title: 'Pay Online',
                          subtitle: 'Secure payment with your credit/debit card.',
                          icon: Icons.credit_card_outlined,
                          isSelected: paymentMethod == 'Online',
                          onTap: () => setState(() => paymentMethod = 'Online'),
                        ),
                      ],
                    ),
                  ),
                  _buildSectionCard(
                    title: '3. Your Details',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                          validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.isEmpty ? 'Please enter your phone number' : null,
                        ),
                        if (deliveryOption == 'Delivery') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: addressController,
                            decoration: const InputDecoration(labelText: 'Delivery Address', prefixIcon: Icon(Icons.home_outlined)),
                            maxLines: 3,
                            validator: (v) => deliveryOption == 'Delivery' && (v == null || v.isEmpty) ? 'Please enter your address' : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
            ),
          ),
          if (_status != CheckoutStatus.idle) _buildProcessingOverlay(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(16.0).copyWith(top: 12),
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(blurRadius: 15, spreadRadius: -5)],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: TextStyle(fontSize: 18)),
                Text('\$${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _status == CheckoutStatus.idle ? placeOrder : null, child: const Text('Place My Order')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_status == CheckoutStatus.processing)
              const CircularProgressIndicator()
                  .animate()
                  .scale(duration: 300.ms),
            if (_status == CheckoutStatus.success)
              const Icon(Icons.check_circle_outline, size: 80)
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              _status == CheckoutStatus.processing ? 'Processing Your Order...' : 'Order Placed Successfully!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Please wait, you will be redirected shortly.',
              style: TextStyle(fontSize: 14),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  String _generateRandomOrderId() {
    return 'BH-${Random().nextInt(90000) + 10000}';
  }

  Future<Map<String, dynamic>?> _showOnlinePaymentForm() async {
    final emailController = TextEditingController();
    final cardController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email for receipt'), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || !v.isEmail ? 'Enter a valid email' : null),
                const SizedBox(height: 10),
                TextFormField(controller: cardController, decoration: const InputDecoration(labelText: 'Card Number'), keyboardType: TextInputType.number, maxLength: 16, validator: (v) => v == null || v.length != 16 ? 'Enter a 16-digit card number' : null),
                TextFormField(controller: expiryController, decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'), keyboardType: TextInputType.datetime, maxLength: 5, validator: (v) => v == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(v) ? 'Enter valid MM/YY' : null),
                TextFormField(controller: cvvController, decoration: const InputDecoration(labelText: 'CVV'), keyboardType: TextInputType.number, maxLength: 3, obscureText: true, validator: (v) => v == null || v.length != 3 ? 'Enter a 3-digit CVV' : null),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop({'success': true, 'email': emailController.text.trim()});
                }
              },
              child: const Text('Pay Now')),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({required this.title, required this.subtitle, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}