import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/tips_screen.dart';
import '../screens/glucose_screen.dart';
import '../screens/diet_screen.dart';
import '../screens/medication_screen.dart';
import '../screens/reports_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vsomrlhikihhvppqsmzs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZzb21ybGhpa2loaHZwcHFzbXpzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4ODc0NzYsImV4cCI6MjA4MTQ2MzQ3Nn0.PZQWxXjRtZ6Z8P1nnpJJjPynR2CamzgdOOmPu1MUmig',
  );

  runApp(const MyApp());
}

// Global variable for easy Supabase access throughout the app
final supabase = Supabase.instance.client;

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
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
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