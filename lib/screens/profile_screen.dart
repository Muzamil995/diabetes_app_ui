import 'package:diabatic/screens/personal_data_screen.dart';
import 'package:diabatic/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  String? _deviceId;

  String fullName = "User";
  String dob = "January 15, 1990";
  String weight = "75 kg";
  String height = "175 cm";
  String diabetesType = "Type 2";
  String bloodType = "B+";

  int age = 0;

  File? _profileImage;
  String? _profileImageUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPersonalData();
  }

  Future<void> _loadPersonalData() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId ??= prefs.getString('personal_device_id') ?? UniqueKey().toString();
    await prefs.setString('personal_device_id', _deviceId!);

    try {
      final response = await supabase
          .from('personal_data')
          .select('full_name, dob, weight, height, diabetes_type, blood_type, profile_image_url')
          .eq('device_id', _deviceId!)
          .maybeSingle();

      if (response != null) {
        final data = response as Map<String, dynamic>;

        fullName = data['full_name'] ?? "User";
        dob = data['dob'] ?? "January 15, 1990";
        weight = data['weight'] ?? "75 kg";
        height = data['height'] ?? "175 cm";
        diabetesType = data['diabetes_type'] ?? "Type 2";
        bloodType = data['blood_type'] ?? "B+";
        _profileImageUrl = data['profile_image_url'];

        // Calculate age
        try {
          final DateFormat format = DateFormat('MMMM d, yyyy');
          final birthDate = format.parse(dob);
          final today = DateTime.now();
          age = today.year - birthDate.year;
          if (today.month < birthDate.month ||
              (today.month == birthDate.month && today.day < birthDate.day)) {
            age--;
          }
        } catch (e) {
          age = 0;
        }
      }
    } catch (e) {
      print('Supabase load error (profile): $e');
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _profileImage = File(pickedFile.path);
    });

    try {
      final fileName = 'profile_$_deviceId.jpg';
      await supabase.storage
          .from('profile_images')
          .upload(fileName, _profileImage!, fileOptions: const FileOptions(upsert: true));

      final url = supabase.storage.from('profile_images').getPublicUrl(fileName);

      await supabase
          .from('personal_data')
          .update({'profile_image_url': url})
          .eq('device_id', _deviceId!);

      setState(() {
        _profileImageUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFFE31E24),
        elevation: 0,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header - Original design restored
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (_profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!) as ImageProvider<Object>?
                            : null),
                        backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                        child: _profileImage == null && _profileImageUrl == null
                            ? Icon(Icons.person, size: 70, color: AppTheme.primaryRed)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryRed,
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Age: $age years",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatCard("Weight", weight, Icons.fitness_center),
                      const SizedBox(width: 20),
                      _buildStatCard("Height", height, Icons.height),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Navigation Menu - Fully restored original design with ListTiles
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person_outline, color: AppTheme.primaryRed),
                    title: const Text("Personal Information"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to Personal Data screen
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>PersonalDataScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.medication, color: AppTheme.primaryRed),
                    title: const Text("Medication Reminder"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/medication');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.restaurant, color: AppTheme.primaryRed),
                    title: const Text("Diet Plan"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/diet');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.bar_chart, color: AppTheme.primaryRed),
                    title: const Text("Health Reports"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/reports');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.settings, color: AppTheme.primaryRed),
                    title: const Text("Settings"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to Settings if exists
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primaryRed),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}