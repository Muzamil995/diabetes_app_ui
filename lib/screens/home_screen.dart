import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  String? _deviceId;

  String fullName = "User";
  String? profileImagePath;
  String? profileImageUrl;

  // Dynamic stats
  String bloodSugar = "-- mg/dL";
  String hba1c = "--%";
  String bmi = "--";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData({bool showLoading = false}) async {
    if (showLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refreshing data...'), duration: Duration(seconds: 1)),
      );
    }

    final prefs = await SharedPreferences.getInstance();

    fullName = prefs.getString('fullName') ?? "User";
    profileImagePath = prefs.getString('profileImagePath');

    _deviceId ??= prefs.getString('personal_device_id') ?? UniqueKey().toString();
    await prefs.setString('personal_device_id', _deviceId!);

    try {
      final personalResponse = await supabase
          .from('personal_data')
          .select('full_name, weight, height, profile_image_url')
          .eq('device_id', _deviceId!)
          .maybeSingle();

      if (personalResponse != null) {
        final data = personalResponse as Map<String, dynamic>;
        fullName = data['full_name'] ?? fullName;
        profileImageUrl = data['profile_image_url'];

        final weightStr = data['weight'] ?? "";
        final heightStr = data['height'] ?? "";

        if (weightStr.isNotEmpty && heightStr.isNotEmpty) {
          final weightKg = double.tryParse(weightStr.replaceAll(RegExp(r'[^0-9.]'), ''));
          final heightCm = double.tryParse(heightStr.replaceAll(RegExp(r'[^0-9.]'), ''));

          if (weightKg != null && heightCm != null && heightCm > 0) {
            final heightM = heightCm / 100;
            final bmiValue = weightKg / (heightM * heightM);
            bmi = bmiValue.toStringAsFixed(1);
          } else {
            bmi = "--";
          }
        } else {
          bmi = "--";
        }
      }
    } catch (e) {
      print('Supabase personal data load error: $e');
      bmi = "--";
    }

    try {
      final bsResponse = await supabase
          .from('blood_sugar_readings')
          .select('value')
          .eq('device_id', _deviceId!)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (bsResponse != null) {
        final value = (bsResponse['value'] as num).toDouble();
        bloodSugar = '${value.toStringAsFixed(0)} mg/dL';
      } else {
        bloodSugar = "-- mg/dL";
      }
    } catch (e) {
      print('Supabase blood sugar load error: $e');
      bloodSugar = "-- mg/dL";
    }

    try {
      final allReadings = await supabase
          .from('blood_sugar_readings')
          .select('value')
          .eq('device_id', _deviceId!);

      if (allReadings.isNotEmpty) {
        final values = allReadings.map((e) => (e['value'] as num).toDouble()).toList();
        final average = values.reduce((a, b) => a + b) / values.length;
        final estimated = (average + 46.7) / 28.7;
        hba1c = estimated.toStringAsFixed(1) + '%';
      } else {
        hba1c = "--%";
      }
    } catch (e) {
      print('Supabase HbA1c calculation error: $e');
      hba1c = "--%";
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: RefreshIndicator(
        onRefresh: () => _loadUserData(showLoading: true),
        color: AppTheme.primaryRed,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Important for pull-to-refresh
          child: Column(
            children: [
              // App Bar with Profile Section - Unchanged
              Container(
                padding:
                const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryRed,
                      AppTheme.primaryRed.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRed.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: 1.0,
                              child: Text(
                                'Welcome,',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.1),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile')
                              .then((_) => _loadUserData()),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              backgroundImage: profileImageUrl != null
                                  ? NetworkImage(profileImageUrl!) as ImageProvider<Object>?
                                  : (profileImagePath != null
                                  ? FileImage(File(profileImagePath!)) as ImageProvider<Object>?
                                  : null),
                              child: profileImageUrl == null && profileImagePath == null
                                  ? Icon(Icons.person, color: AppTheme.primaryRed, size: 32)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _glassQuickStat('Blood Sugar', bloodSugar),
                        _glassQuickStat('HbA1c', hba1c),
                        _glassQuickStat('BMI', bmi),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content - Wrapped in padding, unchanged
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Main Features',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: [
                        _glassFeatureCard(
                          'Glucose',
                          Icons.speed,
                          'Monitor blood sugar',
                              () => Navigator.pushNamed(context, '/glucose'),
                        ),
                        _glassFeatureCard(
                          'Diet',
                          Icons.restaurant,
                          'Meal planner',
                              () => Navigator.pushNamed(context, '/diet'),
                        ),
                        _glassFeatureCard(
                          'Medication',
                          Icons.medication,
                          'Medication reminders',
                              () => Navigator.pushNamed(context, '/medication'),
                        ),
                        _glassFeatureCard(
                          'Reports',
                          Icons.insert_chart,
                          'Health analysis',
                              () => Navigator.pushNamed(context, '/reports'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _glassTipsSection(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // All widgets below remain 100% unchanged
  Widget _glassQuickStat(String label, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassFeatureCard(
      String title, IconData icon, String description, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: AppTheme.primaryRed),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[700], height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassTipsSection(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/tips'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lightbulb_outline,
                      color: AppTheme.primaryRed, size: 24),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips & Articles',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Read the latest health articles',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppTheme.primaryRed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}