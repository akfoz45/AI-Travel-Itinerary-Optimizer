import 'package:flutter/material.dart';

import 'features/auth/screens/splash_screen.dart';

void main() {
  runApp(const TravelPlannerApp());
}

class TravelPlannerApp extends StatelessWidget {
  const TravelPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF6F8FB),

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE0E6EF),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1E88E5),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}