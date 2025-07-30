import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final users = FirebaseFirestore.instance.collection('Users');

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();

  final RxBool isLoading = true.obs;
  final RxBool isUpdating = false.obs;
  final RxString imageUrl = ''.obs;
  final ThemeController themeController = Get.find();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    try {
      final doc = await users.doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        firstNameController.text = data['firstName'] ?? '';
        lastNameController.text = data['lastName'] ?? '';
        phoneController.text = data['phone'] ?? '';
        ageController.text = data['age'] ?? '';
        if (data['image'] != null && data['image'].isNotEmpty) {
          imageUrl.value = data['image'];
        } else {
          imageUrl.value = 'https://avatar.iran.liara.run/username?username=${data['firstName']}+${data['lastName']}';
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserData() async {
    isUpdating.value = true;
    try {
      await users.doc(user.uid).update({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'age': ageController.text.trim(),
      });
      Get.snackbar('Success', 'Profile updated successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isUpdating.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings'),
           automaticallyImplyLeading: false,),
      
      body: Obx(
        () => isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- PROFILE AVATAR CARD ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Obx(() => CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                backgroundImage:
                                    imageUrl.value.isNotEmpty ? NetworkImage(imageUrl.value) : null,
                                child: imageUrl.value.isEmpty
                                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                                    : null,
                              )),
                          const SizedBox(height: 16),
                          Text(
                            '${firstNameController.text} ${lastNameController.text}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(user.email!, style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- EDITABLE PROFILE INFO ---
                  Text('Edit Information', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildTextField(firstNameController, 'First Name', Icons.person_outline),
                  _buildTextField(lastNameController, 'Last Name', Icons.person),
                  _buildTextField(phoneController, 'Phone', Icons.phone_outlined, TextInputType.phone),
                  _buildTextField(ageController, 'Age', Icons.cake_outlined, TextInputType.number),
                  const SizedBox(height: 20),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isUpdating.value ? null : updateUserData,
                          icon: isUpdating.value
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_alt_outlined),
                          label: Text(isUpdating.value ? 'Updating...' : 'Save Changes'),
                        ),
                      )),
                  const Divider(height: 48),

                  // --- SETTINGS ---
                  Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    title: const Text('Dark Mode'),
                    value: Get.isDarkMode,
                    secondary: Icon(Get.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                    onChanged: (value) {
                      themeController.switchTheme();
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}