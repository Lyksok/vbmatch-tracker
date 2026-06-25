import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const VolleyScoreApp());
}

class VolleyScoreApp extends StatelessWidget {
  const VolleyScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volley Score/Stats',
      debugShowCheckedModeBanner: false,
      // Define a custom, premium theme using curated colors: Deep Navy (#0F172A) & Warm Amber (#F59E0B)
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFFF59E0B),
          background: const Color(0xFFF1F5F9),
        ),
        // Style standard buttons globally for consistency
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        // Text styling customization
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Color(0xFF334155)),
        ),
        // Style chips globally
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
