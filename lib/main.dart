import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_screen.dart'; //

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ชุดกุญแจจากรูป image_7bf9c1.png
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBKI_uI4xFI-n6sL7sm21q1dwlnzNpyft8", //
      authDomain: "greenbuddy-d58d6.firebaseapp.com", //
      projectId: "greenbuddy-d58d6", //
      storageBucket: "greenbuddy-d58d6.firebasestorage.app", //
      messagingSenderId: "545189711037", //
      appId: "1:545189711037:web:1b1f60a69a08bb1c463bd4", //
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
      title: 'Greenbuddy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // สั่งให้เปิดมาเจอหน้า Welcome เพื่อทำการ Auto-Login
      home: const WelcomeScreen(),
    );
  }
}
