// main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebaseproject/admin/home/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'firebase_options.dart';
import 'theme/app_themes.dart';
import 'theme/theme_controller.dart';

import 'user/auth/login.dart';
import 'user/home/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final themeController = Get.put(ThemeController());

  Future<Widget> getInitialScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    final uid = user.uid;
    final adminDoc = await FirebaseFirestore.instance.collection('Admins').doc(uid).get();
    final userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();

    if (adminDoc.exists) return const AdminHomeScreen();
    if (userDoc.exists) return const HomeScreen();
    return const LoginScreen(); // fallback
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: getInitialScreen(),
      builder: (context, snapshot) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pro App',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeController.theme,
          home: snapshot.connectionState == ConnectionState.done
              ? snapshot.data
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }
}
