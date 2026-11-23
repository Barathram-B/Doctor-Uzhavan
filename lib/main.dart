import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const DoctorUzhavanApp());
}

class DoctorUzhavanApp extends StatelessWidget {
  const DoctorUzhavanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Uzhavan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F9F5),
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF81C784),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}