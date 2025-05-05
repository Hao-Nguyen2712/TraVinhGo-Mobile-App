import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Đợi sau frame đầu tiên mới push để tránh lỗi context chưa sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF158247),
      body: Center(
        child: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Aclonica',
          ),
          child: AnimatedTextKit(
            animatedTexts: [
              TyperAnimatedText(
                'TraVinhGo',
                speed: Duration(microseconds: 200),
              ),
            ],
            totalRepeatCount: 1,
            pause: Duration(milliseconds: 500),
          ),
        ),
      ),
    );
  }
}
