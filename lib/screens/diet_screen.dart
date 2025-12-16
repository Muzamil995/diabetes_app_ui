import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({Key? key}) : super(key: key);

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  List<Map<String, String>> meals = [];
  int _totalCalories = 0;
  static const int dailyTargetCalories = 1800; // Change this if needed

  final supabase = Supabase.instance.client;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedMeals = prefs.getString('diet_meals');

    if (storedMeals != null) {
      setState(() {
        meals = List<Map<String, String>>.from(json.decode(storedMeals));
      });
    }

    _deviceId ??= prefs.getString('device_id') ?? UniqueKey().toString();
    await prefs.setString('device_id', _deviceId!);

    try {
      final response = await supabase
          .from('diet_meals')
          .select()
          .eq('device_id', _deviceId!);

      if (response.isNotEmpty) {
        setState(() {
          meals = (response as List)
              .map((e) => {
            'title': e['title'] as String,
            'time': e['time'] as String,
            'description': e['description'] as String,
            'calories': e['calories'] as String,
          })
              .toList();
        });
      }
    } catch (e) {
      print('Supabase load error: $e');
    }

    // Recalculate total calories after loading (from local or cloud)
    _totalCalories = meals.fold(0, (sum, meal) {
      return sum + (int.tryParse(meal['calories'] ?? '0') ?? 0);
    });

    if (mounted) setState(() {});
  }

  Future<void> _saveMeals() async {
    // Recalculate total calories
    _totalCalories = meals.fold(0, (sum, meal) {
      return sum + (int.tryParse(meal['calories'] ?? '0') ?? 0);
    });

    // Save locally
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('diet_meals', json.encode(meals));

    // Save to Supabase
    if (_deviceId == null) return;

    try {
      await supabase
          .from('diet_meals')
          .delete()
          .eq('device_id', _deviceId!);

      if (meals.isNotEmpty) {
        final List<Map<String, dynamic>> dataToInsert = meals.map((meal) {
          return {
            'device_id': _deviceId,
            'title': meal['title'],
            'time': meal['time'],
            'description': meal['description'],
            'calories': meal['calories'],
          };
        }).toList();

        await supabase.from('diet_meals').insert(dataToInsert);
      }
    } catch (e) {
      print('Supabase save error: $e');
    }

    if (mounted) setState(() {});
  }

  void _addMeal() {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    final descriptionController = TextEditingController();
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Meal'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Meal Name'),
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time (HH:mm)'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  timeController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  caloriesController.text.isNotEmpty) {
                setState(() {
                  meals.add({
                    'title': titleController.text,
                    'time': timeController.text,
                    'description': descriptionController.text,
                    'calories': caloriesController.text,
                  });
                });
                _saveMeals();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteMeal(int index) {
    setState(() {
      meals.removeAt(index);
    });
    _saveMeals();
  }

  void _showCalendar() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected date: ${DateFormat('yyyy-MM-dd').format(picked)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Plan',style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showCalendar,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dynamic Calorie Summary
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Calories Today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_totalCalories',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' / $dailyTargetCalories',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                        ),
                      ),
                      const Text(
                        ' kcal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      NutrientInfo(label: 'Carbs', amount: '150g', percentage: '60%'),
                      NutrientInfo(label: 'Protein', amount: '75g', percentage: '25%'),
                      NutrientInfo(label: 'Fat', amount: '40g', percentage: '15%'),
                    ],
                  ),
                ],
              ),
            ),
            // Meal List
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...meals.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> meal = entry.value;
                    return MealCard(
                      title: meal['title']!,
                      time: meal['time']!,
                      description: meal['description']!,
                      calories: meal['calories']!,
                      onDelete: () => _deleteMeal(index),
                    );
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
        onPressed: _addMeal,
      ),
    );
  }
}

class NutrientInfo extends StatelessWidget {
  final String label;
  final String amount;
  final String percentage;

  const NutrientInfo({
    required this.label,
    required this.amount,
    required this.percentage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(percentage, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class MealCard extends StatelessWidget {
  final String title;
  final String time;
  final String description;
  final String calories;
  final VoidCallback onDelete;

  const MealCard({
    required this.title,
    required this.time,
    required this.description,
    required this.calories,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, color: AppTheme.primaryRed, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 4),
                Text(calories, style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}