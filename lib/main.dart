import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/tips_screen.dart';
import '../screens/glucose_screen.dart';
import '../screens/diet_screen.dart';
import '../screens/medication_screen.dart';
import '../screens/reports_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiabetesCare',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/tips': (context) => const TipsScreen(),
        '/glucose': (context) => const GlucoseScreen(),
        '/diet': (context) => const DietScreen(),
        '/medication': (context) => const MedicationScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}
