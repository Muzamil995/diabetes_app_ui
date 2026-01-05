import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  // Added Supabase

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({Key? key}) : super(key: key);

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  // Controllers for form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _diabetesTypeController = TextEditingController();
  final TextEditingController _diagnosedSinceController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();

  // Supabase
  final supabase = Supabase.instance.client;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load from SharedPreferences first (offline fallback)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _fullNameController.text = prefs.getString('fullName') ?? "User";
    _dobController.text = prefs.getString('dob') ?? "January 15, 1990";
    _genderController.text = prefs.getString('gender') ?? "Male";
    _emailController.text = prefs.getString('email') ?? "User@email.com";
    _phoneController.text = prefs.getString('phone') ?? "+62 812-3456-7890";
    _addressController.text = prefs.getString('address') ?? "Jl. Sudirman No.";
    _diabetesTypeController.text = prefs.getString('diabetesType') ?? "Type 2";
    _diagnosedSinceController.text = prefs.getString('diagnosedSince') ?? "January 2020";
    _bloodTypeController.text = prefs.getString('bloodType') ?? "B+";
    _weightController.text = prefs.getString('weight') ?? "75 kg";
    _heightController.text = prefs.getString('height') ?? "175 cm";
    _allergiesController.text = prefs.getString('allergies') ?? "None";
    _emergencyNameController.text = prefs.getString('emergencyName') ?? "Sarah Wijaya";
    _relationshipController.text = prefs.getString('relationship') ?? "Wife";
    _emergencyPhoneController.text = prefs.getString('emergencyPhone') ?? "+62 812-9876-5432";

    // Generate/load device_id
    _deviceId ??= prefs.getString('personal_device_id') ?? UniqueKey().toString();
    await prefs.setString('personal_device_id', _deviceId!);

    // Load from Supabase (cloud priority)
    try {
      final response = await supabase
          .from('personal_data')
          .select()
          .eq('device_id', _deviceId!)
          .maybeSingle();

      if (response != null) {
        final data = response as Map<String, dynamic>;
        _fullNameController.text = data['full_name'] ?? _fullNameController.text;
        _dobController.text = data['dob'] ?? _dobController.text;
        _genderController.text = data['gender'] ?? _genderController.text;
        _emailController.text = data['email'] ?? _emailController.text;
        _phoneController.text = data['phone'] ?? _phoneController.text;
        _addressController.text = data['address'] ?? _addressController.text;
        _diabetesTypeController.text = data['diabetes_type'] ?? _diabetesTypeController.text;
        _diagnosedSinceController.text = data['diagnosed_since'] ?? _diagnosedSinceController.text;
        _bloodTypeController.text = data['blood_type'] ?? _bloodTypeController.text;
        _weightController.text = data['weight'] ?? _weightController.text;
        _heightController.text = data['height'] ?? _heightController.text;
        _allergiesController.text = data['allergies'] ?? _allergiesController.text;
        _emergencyNameController.text = data['emergency_name'] ?? _emergencyNameController.text;
        _relationshipController.text = data['relationship'] ?? _relationshipController.text;
        _emergencyPhoneController.text = data['emergency_phone'] ?? _emergencyPhoneController.text;

        // Sync to local prefs
        _saveDataToPrefs();
      }
    } catch (e) {
      print('Supabase load error (personal data): $e');
      // Fallback to local data
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveDataToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', _fullNameController.text);
    await prefs.setString('dob', _dobController.text);
    await prefs.setString('gender', _genderController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('phone', _phoneController.text);
    await prefs.setString('address', _addressController.text);
    await prefs.setString('diabetesType', _diabetesTypeController.text);
    await prefs.setString('diagnosedSince', _diagnosedSinceController.text);
    await prefs.setString('bloodType', _bloodTypeController.text);
    await prefs.setString('weight', _weightController.text);
    await prefs.setString('height', _heightController.text);
    await prefs.setString('allergies', _allergiesController.text);
    await prefs.setString('emergencyName', _emergencyNameController.text);
    await prefs.setString('relationship', _relationshipController.text);
    await prefs.setString('emergencyPhone', _emergencyPhoneController.text);
  }

  Future<void> _saveData() async {
    // Save locally
    await _saveDataToPrefs();

    // Save to Supabase (upsert - update if exists, insert if not)
    try {
      await supabase.from('personal_data').upsert({
        'device_id': _deviceId,
        'full_name': _fullNameController.text,
        'dob': _dobController.text,
        'gender': _genderController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'diabetes_type': _diabetesTypeController.text,
        'diagnosed_since': _diagnosedSinceController.text,
        'blood_type': _bloodTypeController.text,
        'weight': _weightController.text,
        'height': _heightController.text,
        'allergies': _allergiesController.text,
        'emergency_name': _emergencyNameController.text,
        'relationship': _relationshipController.text,
        'emergency_phone': _emergencyPhoneController.text,
      });
    } catch (e) {
      print('Supabase save error (personal data): $e');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data saved successfully")),
    );
    setState(() {

    });
  }

  void _showEditForm() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text("Edit Personal Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Color(0xFFE31E24))),
                const SizedBox(height: 10),
                // Personal Info
                TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: "Full Name")),
                TextField(controller: _dobController, decoration: const InputDecoration(labelText: "Date of Birth")),
                TextField(controller: _genderController, decoration: const InputDecoration(labelText: "Gender")),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
                TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
                TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Address")),
                const SizedBox(height: 10),
                // Medical Info
                TextField(controller: _diabetesTypeController, decoration: const InputDecoration(labelText: "Diabetes Type")),
                TextField(controller: _diagnosedSinceController, decoration: const InputDecoration(labelText: "Diagnosed Since")),
                TextField(controller: _bloodTypeController, decoration: const InputDecoration(labelText: "Blood Type")),
                TextField(controller: _weightController, decoration: const InputDecoration(labelText: "Weight")),
                TextField(controller: _heightController, decoration: const InputDecoration(labelText: "Height")),
                TextField(controller: _allergiesController, decoration: const InputDecoration(labelText: "Allergies")),
                const SizedBox(height: 10),
                // Emergency Contact
                TextField(controller: _emergencyNameController, decoration: const InputDecoration(labelText: "Emergency Name")),
                TextField(controller: _relationshipController, decoration: const InputDecoration(labelText: "Relationship")),
                TextField(controller: _emergencyPhoneController, decoration: const InputDecoration(labelText: "Emergency Phone")),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _saveData();
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF6C7BFF),
        elevation: 0,
        title: const Text(
          "Personal Data",
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
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white,),
            onPressed: _showEditForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildPersonalInfoSection(),
            _buildMedicalInfoSection(),
            _buildEmergencyContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
            child: Icon(Icons.person, size: 50, color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 15),
          Text(
            _fullNameController.text,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "ID: DM-2024-001",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection("Personal Information", [
      _buildInfoItem("Full Name", _fullNameController.text),
      _buildInfoItem("Date of Birth", _dobController.text),
      _buildInfoItem("Gender", _genderController.text),
      _buildInfoItem("Email", _emailController.text),
      _buildInfoItem("Phone Number", _phoneController.text),
      _buildInfoItem("Address", _addressController.text),
    ]);
  }

  Widget _buildMedicalInfoSection() {
    return _buildSection("Medical Information", [
      _buildInfoItem("Diabetes Type", _diabetesTypeController.text),
      _buildInfoItem("Diagnosed Since", _diagnosedSinceController.text),
      _buildInfoItem("Blood Type", _bloodTypeController.text),
      _buildInfoItem("Weight", _weightController.text),
      _buildInfoItem("Height", _heightController.text),
      _buildInfoItem("Allergies", _allergiesController.text),
    ]);
  }

  Widget _buildEmergencyContactSection() {
    return _buildSection("Emergency Contact", [
      _buildInfoItem("Name", _emergencyNameController.text),
      _buildInfoItem("Relationship", _relationshipController.text),
      _buildInfoItem("Phone Number", _emergencyPhoneController.text),
    ]);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}