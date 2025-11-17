import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips & Articles'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildArticleCard(
            context,
            'Tips to Keep Blood Sugar Stable',
            'Learn effective ways to manage your blood sugar levels. '
                'These include maintaining a balanced diet, monitoring sugar intake, '
                'exercising regularly, and staying hydrated throughout the day.',
            Icons.bloodtype,
          ),
          _buildArticleCard(
            context,
            'Healthy Meal Plans for Diabetics',
            'Complete guide to creating healthy meal plans. '
                'Focus on including high-fiber foods, lean proteins, and '
                'low-glycemic index meals to help maintain sugar levels.',
            Icons.restaurant_menu,
          ),
          _buildArticleCard(
            context,
            'Safe Exercises for Diabetic Patients',
            'Recommended physical activities suitable for diabetics. '
                'These include walking, swimming, yoga, and light strength training, '
                'all aimed at controlling blood sugar safely.',
            Icons.fitness_center,
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, String title, String description, IconData iconData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Center(
              child: Icon(iconData, size: 50, color: Colors.grey[400]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description.length > 60 ? description.substring(0, 60) + '...' : description,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _showReadMoreDialog(context, title, description);
                  },
                  child: Text(
                    'Read More',
                    style: TextStyle(color: AppTheme.primaryRed),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReadMoreDialog(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(description, style: const TextStyle(fontSize: 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
