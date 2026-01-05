import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class GlucoseScreen extends StatefulWidget {
  const GlucoseScreen({Key? key}) : super(key: key);

  @override
  State<GlucoseScreen> createState() => _GlucoseScreenState();
}

class _GlucoseScreenState extends State<GlucoseScreen> {
  List<Map<String, String>> readings = [];
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() => _isLoading = true);

    // Load from SharedPreferences first (fast)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedReadings = prefs.getString('glucose_readings');
    if (storedReadings != null) {
      setState(() {
        readings = List<Map<String, String>>.from(
            (json.decode(storedReadings) as List)
                .map((e) => Map<String, String>.from(e as Map<String, dynamic>))
                .toList()
        );
      });
    }

    // Then sync with Supabase (if user is logged in)
    await _syncWithSupabase();

    setState(() => _isLoading = false);
  }

  Future<void> _syncWithSupabase() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Fetch readings from Supabase
      final response = await supabase
          .from('glucose_readings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        List<Map<String, String>> supabaseReadings = [];
        for (var item in response) {
          supabaseReadings.add({
            'value': item['value'].toString(),
            'label': item['label'].toString(),
            'time': item['time'].toString(),
            'id': item['id'].toString(),
          });
        }

        // Update local data with Supabase data
        setState(() {
          readings = supabaseReadings;
        });

        // Save to SharedPreferences
        await _saveReadingsLocally();
      }
    } catch (e) {
      print('Error syncing with Supabase: $e');
      // Continue with local data if Supabase fails
    }
  }

  Future<void> _saveReadingsLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('glucose_readings', json.encode(readings));
  }

  Future<void> _saveReadings() async {
    // Save to SharedPreferences (local)
    await _saveReadingsLocally();

    // Save to Supabase (cloud)
    await _saveToSupabase();
  }

  Future<void> _saveToSupabase() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get the last reading (most recently added)
      if (readings.isNotEmpty) {
        final lastReading = readings.last;

        // Insert to Supabase
        await supabase.from('glucose_readings').insert({
          'user_id': user.id,
          'value': double.parse(lastReading['value']!),
          'label': lastReading['label'],
          'time': lastReading['time'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving to Supabase: $e');
      // Data is still saved locally in SharedPreferences
    }
  }

  Future<void> _deleteFromSupabase(String? id) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null || id == null) return;

      await supabase
          .from('glucose_readings')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting from Supabase: $e');
    }
  }

  void _addReading() {
    final valueController = TextEditingController();
    final labelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Glucose Reading'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Glucose value (mg/dL)',
              ),
            ),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label (e.g., Before breakfast)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (valueController.text.isNotEmpty &&
                  labelController.text.isNotEmpty) {
                String time =
                DateFormat('HH:mm').format(DateTime.now());
                setState(() {
                  readings.add({
                    'value': valueController.text,
                    'label': labelController.text,
                    'time': time,
                  });
                });
                await _saveReadings();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteReading(int index) async {
    final reading = readings[index];

    setState(() {
      readings.removeAt(index);
    });

    await _saveReadingsLocally();

    // Delete from Supabase if it has an ID
    if (reading.containsKey('id')) {
      await _deleteFromSupabase(reading['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<FlSpot> chartSpots = [];
    for (int i = 0; i < readings.length; i++) {
      chartSpots.add(FlSpot(
          i.toDouble(), double.tryParse(readings[i]['value']!) ?? 0));
    }

    double average = 0;
    if (readings.isNotEmpty) {
      average = readings
          .map((e) => double.tryParse(e['value']!) ?? 0)
          .reduce((a, b) => a + b) /
          readings.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Monitor',style: TextStyle(color: Colors.white),),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _syncWithSupabase,
            tooltip: 'Sync with cloud',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Stats Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Average Glucose',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        average.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      const Text(
                        ' mg/dL',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Graph
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < readings.length) {
                            return Text(readings[value.toInt()]['time']!);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartSpots.isNotEmpty
                          ? chartSpots
                          : [const FlSpot(0, 0)],
                      isCurved: true,
                      color: AppTheme.primaryRed,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Readings
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Readings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...readings.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> e = entry.value;
                    return _buildReadingItem(
                        e['value']!, e['label']!, e['time']!, index);
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryRed,
        child: const Icon(Icons.add,color: Colors.white,),
        onPressed: _addReading,
      ),
    );
  }

  Widget _buildReadingItem(
      String value, String label, String time, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.primaryRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red[400]),
                onPressed: () => _deleteReading(index),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }
}