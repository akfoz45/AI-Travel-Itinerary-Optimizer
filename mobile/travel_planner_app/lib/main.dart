import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/screens/splash_screen.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const TravelPlannerApp(),
    ),
  );
}

class TravelPlannerApp extends StatelessWidget {
  const TravelPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4F46E5); 
    const secondaryColor = Color(0xFF0EA5E9); 
    
    const lightBgColor = Color(0xFFF8FAFC);
    const lightCardColor = Colors.white;
    const lightBorderColor = Color(0xFFE2E8F0);
    
    const darkBgColor = Color(0xFF0F172A); 
    const darkCardColor = Color(0xFF1E293B); 
    const darkBorderColor = Color(0xFF334155);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Travel Planner',
          debugShowCheckedModeBanner: false,
          
          themeMode: themeProvider.themeMode,

          theme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              secondary: secondaryColor,
              surface: lightBgColor,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: lightBgColor,
            
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1E293B), 
              elevation: 0.5,
              scrolledUnderElevation: 1,
              iconTheme: IconThemeData(color: primaryColor),
            ),
            
            cardTheme: CardThemeData(
              color: lightCardColor,
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFF1F5F9), width: 1), 
              ),
            ),
            
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: lightCardColor,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              labelStyle: const TextStyle(color: Color(0xFF64748B)),
              prefixIconColor: primaryColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: lightBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: lightBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              secondary: secondaryColor,
              surface: darkBgColor,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: darkBgColor,
            
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              backgroundColor: darkBgColor,
              foregroundColor: Colors.white,
              elevation: 0.5,
              scrolledUnderElevation: 1,
              iconTheme: IconThemeData(color: primaryColor),
            ),
            
            cardTheme: CardThemeData(
              color: darkCardColor,
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: darkBorderColor, width: 1),
              ),
            ),
            
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: darkCardColor,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIconColor: primaryColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: darkBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: darkBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
          ),
          
          home: const SplashScreen(),
        );
      },
    );
  }
}