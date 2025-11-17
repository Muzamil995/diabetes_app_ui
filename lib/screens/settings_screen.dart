import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _reminderEnabled = true;
  String _selectedLanguage = 'Bahasa Indonesia';
  String _glucoseUnit = 'mg/dL';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              "General",
              [
                _buildLanguageSelector(),
                _buildUnitSelector(),
                _buildSwitchTile(
                  "Dark Mode",
                  "Enable dark theme",
                  Icons.dark_mode,
                  _darkModeEnabled,
                      (value) => setState(() => _darkModeEnabled = value),
                ),
              ],
            ),
            _buildSection(
              "Notifications",
              [
                _buildSwitchTile(
                  "Notifications",
                  "Enable notifications",
                  Icons.notifications,
                  _notificationsEnabled,
                      (value) => setState(() => _notificationsEnabled = value),
                ),
                _buildSwitchTile(
                  "Reminders",
                  "Blood sugar check reminders",
                  Icons.alarm,
                  _reminderEnabled,
                      (value) => setState(() => _reminderEnabled = value),
                ),
              ],
            ),
            _buildSection(
              "Data & Privacy",
              [
                _buildActionTile(
                  "Export Data",
                  "Download your health data",
                  Icons.download,
                      () {},
                ),
                _buildActionTile(
                  "Delete Data",
                  "Delete all app data",
                  Icons.delete_outline,
                      () => _showDeleteConfirmation(),
                ),
                _buildActionTile(
                  "Privacy Policy",
                  "Read our privacy policy",
                  Icons.privacy_tip_outlined,
                      () {},
                ),
              ],
            ),
            _buildSection(
              "About",
              [
                _buildActionTile(
                  "App Version",
                  "1.0.0",
                  Icons.info_outline,
                      () {},
                  showArrow: false,
                ),
                _buildActionTile(
                  "Rate App",
                  "Rate this app",
                  Icons.star_outline,
                      () {},
                ),
                _buildActionTile(
                  "Contact Us",
                  "Send feedback",
                  Icons.mail_outline,
                      () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.language, color: AppTheme.primaryRed),
      ),
      title: const Text("Language"),
      subtitle: const Text("Select app language"),
      trailing: DropdownButton<String>(
        value: _selectedLanguage,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(
            value: 'Bahasa Indonesia',
            child: Text('Bahasa Indonesia'),
          ),
          DropdownMenuItem(
            value: 'English',
            child: Text('English'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedLanguage = value);
          }
        },
      ),
    );
  }

  Widget _buildUnitSelector() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.straighten, color: AppTheme.primaryRed),
      ),
      title: const Text("Glucose Unit"),
      subtitle: const Text("Select measurement unit"),
      trailing: DropdownButton<String>(
        value: _glucoseUnit,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(
            value: 'mg/dL',
            child: Text('mg/dL'),
          ),
          DropdownMenuItem(
            value: 'mmol/L',
            child: Text('mmol/L'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _glucoseUnit = value);
          }
        },
      ),
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryRed),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryRed,
      ),
    );
  }

  Widget _buildActionTile(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap, {
        bool showArrow = true,
      }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryRed),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: showArrow
          ? Icon(Icons.chevron_right, color: Colors.grey[400])
          : null,
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Data"),
        content: const Text(
          "Are you sure you want to delete all data? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Implement delete functionality
              Navigator.pop(context);
            },
            child: Text(
              "Delete",
              style: TextStyle(color: AppTheme.primaryRed),
            ),
          ),
        ],
      ),
    );
  }
}
