import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clinic_finance_pro/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Pure Hive Hardware Storage Engine
  try {
    await Hive.initFlutter();
    debugPrint('Hive Hardware Database initialized for Clinic Finance Pro.');
  } catch (e) {
    debugPrint('Hive main init info: $e');
  }

  runApp(const ClinicFinanceApp());
}

class ClinicFinanceApp extends StatelessWidget {
  const ClinicFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinic Finance Pro - Syed Sadiq Poly Clinic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E), // Deep Teal
          primary: const Color(0xFF0F766E),
          surface: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}
