import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_hub.dart'; // 🛠️ ต้องเรียกหน้าหลักมาเตรียมไว้

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _autoLoginAndNavigate(); // 🛠️ สั่งให้ทำงานทันทีที่เปิดหน้าจอ
  }

  Future<void> _autoLoginAndNavigate() async {
    try {
      // 1. หน่วงเวลา 2 วินาทีให้คนเห็นโลโก้ Greenbuddy
      await Future.delayed(const Duration(seconds: 2));

      // 2. ล็อกอินแบบ Anonymous (ไม่ต้องใช้เมล/รหัสผ่าน)
      await FirebaseAuth.instance.signInAnonymously();

      if (mounted) {
        // 3. พาเข้าหน้าหลักทันที และลบหน้า Welcome ทิ้งจากประวัติ (กด Back กลับมาไม่ได้)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainHub()),
        );
      }
    } catch (e) {
      // ถ้ามี Error ให้แจ้งเตือน (เช่น ลืมเปิด Anonymous ใน Firebase)
      debugPrint("Login Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // โลโก้แอป Greenbuddy
            const Icon(Icons.eco_outlined, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Greenbuddy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.green), // ตัวหมุนโหลด
          ],
        ),
      ),
    );
  }
}
