

// ignore_for_file: avoid_unnecessary_containers, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/admin/category/categories.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController detailController = TextEditingController();

    // User? userId = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create detail"),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // ignore: duplicate_ignore
      // ignore: avoid_unnecessary_containers
      body: Container(
        margin: EdgeInsets.all(30),
        child: Column(
          children: [
            Container(
              child: TextFormField(
                controller: titleController,
                decoration: InputDecoration(hintText: "Title"),
              ),
            ),
              Container(
              child: TextFormField(
                controller: detailController,
                maxLines: null,
                decoration: InputDecoration(hintText: "Add detail"),
              ),
            ),
            ElevatedButton(onPressed: () async{
              var title = titleController.text.trim();
               var detail = detailController.text.trim();

               if(title != "" && detail != "")
               {
                try{
                 await FirebaseFirestore.instance.collection("categories").doc().set({
                    "createdAt":DateTime.now() ,
                    "title":title,
                    "detail":detail,
                    // "userId":userId/?.uid
                  });
                  Get.to(()=>CategoriesScreen());
                }
                catch(e)
                {
                  print("Error $e");
                }
               }


            }, child: Text("Add detail"))
          ],
        ),
      ),
    );
  }
}