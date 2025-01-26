import 'package:flutter/material.dart';
import 'package:madproject/auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyADeh4jO-gXxsj9GXRaWOE6-GqJkrCqZcg",
        appId: "1:1034130925655:android:c5ed8903b2d2f9cae4db12",
        messagingSenderId: "1034130925655",
        projectId: "madproject-fd7fc",
      )

  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override

  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
    );
  }
}