import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
  apiKey: "AIzaSyAqte7GI0abmJ3xu5va-p9ZyO6SmM5hjJE",
  authDomain: "harvestguard-bd.firebaseapp.com",
  projectId: "harvestguard-bd",
  storageBucket: "harvestguard-bd.firebasestorage.app",
  messagingSenderId: "1084770852742",
  appId: "1:1084770852742:web:4badb24c5f1365c7279607",
  measurementId: "G-EW56M5MGXQ"
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HarvestGuard',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(), // Start directly from HomeScreen
    );
  }
}
