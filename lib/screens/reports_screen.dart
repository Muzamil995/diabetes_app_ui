import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';  // To open the saved PDF
import 'dart:io';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final supabase = Supabase.instance.client;
  String? _deviceId;

  List<Map<String, dynamic>> bloodSugarReadings = [];

  double averageBloodSugar = 0;
  double estimatedHbA1c = 0;
  double highest = 0;
  double lowest = 0;
  double inTargetPercentage = 0;

  List<double> weeklyValues = [0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId ??= prefs.getString('report_device_id') ?? UniqueKey().toString();
    await prefs.setString('report_device_id', _deviceId!);

    try {
      final response = await supabase
          .from('blood_sugar_readings')
          .select()
          .eq('device_id', _deviceId!)
          .order('date', ascending: false);

      if (response.isNotEmpty) {
        bloodSugarReadings = List<Map<String, dynamic>>.from(response);

        final values = bloodSugarReadings
            .map((e) => (e['value'] as num).toDouble())
            .toList();

        if (values.isNotEmpty) {
          averageBloodSugar = values.reduce((a, b) => a + b) / values.length;
          highest = values.reduce((a, b) => a > b ? a : b);
          lowest = values.reduce((a, b) => a < b ? a : b);

          estimatedHbA1c = (averageBloodSugar + 46.7) / 28.7;
          estimatedHbA1c = double.parse(estimatedHbA1c.toStringAsFixed(1));

          final inTarget = values.where((v) => v >= 70 && v <= 180).length;
          inTargetPercentage = (inTarget / values.length * 100);
          inTargetPercentage = double.parse(inTargetPercentage.toStringAsFixed(0));

          _calculateWeeklyTrend();
        }
      }
    } catch (e) {
      print('Supabase load error (reports): $e');
    }

    if (mounted) setState(() {});
  }

  void _calculateWeeklyTrend() {
    final now = DateTime.now();
    final todayWeekday = now.weekday;

    weeklyValues = List.filled(7, 0.0);
    List<int> countPerDay = List.filled(7, 0);

    for (var reading in bloodSugarReadings) {
      final dateStr = reading['date'] as String?;
      if (dateStr == null) continue;

      final readingDate = DateTime.tryParse(dateStr);
      if (readingDate == null) continue;

      final daysAgo = now.difference(readingDate).inDays;
      if (daysAgo < 0 || daysAgo >= 7) continue;

      int index = (todayWeekday - 1 - daysAgo) % 7;
      if (index < 0) index += 7;

      double value = (reading['value'] as num).toDouble();
      weeklyValues[index] += value;
      countPerDay[index]++;
    }

    for (int i = 0; i < 7; i++) {
      if (countPerDay[i] > 0) {
        weeklyValues[i] = weeklyValues[i] / countPerDay[i];
        weeklyValues[i] = double.parse(weeklyValues[i].toStringAsFixed(0));
      } else {
        weeklyValues[i] = 0;
      }
    }
  }

  void _addReading() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Blood Sugar Reading'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Value (mg/dL)',
            hintText: 'e.g. 125',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              final value = double.tryParse(text);
              if (value == null || value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number')),
                );
                return;
              }

              try {
                await supabase.from('blood_sugar_readings').insert({
                  'device_id': _deviceId,
                  'value': value,
                  'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                });

                Navigator.pop(context);
                _loadReportData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reading added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // New: Export to PDF
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('MMMM dd, yyyy');
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Health Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Generated on: ${dateFormat.format(now)}', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 32),

              pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Average Blood Sugar')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${averageBloodSugar.toStringAsFixed(0)} mg/dL')),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Estimated HbA1c')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('$estimatedHbA1c%')),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Highest Reading')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${highest.toStringAsFixed(0)} mg/dL')),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Lowest Reading')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${lowest.toStringAsFixed(0)} mg/dL')),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('In Target (70-180 mg/dL)')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('$inTargetPercentage%')),
                  ]),
                ],
              ),
              pw.SizedBox(height: 32),

              pw.Text('Weekly Average Trend', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Day')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Average (mg/dL)')),
                  ]),
                  ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].asMap().entries.map((entry) {
                    int idx = entry.key;
                    String day = entry.value;
                    return pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(day)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(weeklyValues[idx] > 0 ? weeklyValues[idx].toStringAsFixed(0) : '-')),
                    ]);
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/health_report_${DateFormat('yyyyMMdd').format(now)}.pdf');
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF exported successfully!'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              OpenFile.open(file.path);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: const Text('Health Reports',style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... (all previous widgets unchanged: summary cards, chart, statistics)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Average\nBlood Sugar',
                      averageBloodSugar > 0 ? averageBloodSugar.toStringAsFixed(0) : '--',
                      'mg/dL',
                      Icons.speed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Estimated\nHbA1c',
                      estimatedHbA1c > 0 ? estimatedHbA1c.toString() : '--',
                      '%',
                      Icons.analytics,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.grey, spreadRadius: 5, blurRadius: 7, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 200,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return Text(titles[value.toInt()], style: const TextStyle(fontSize: 12));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (i) => _buildBarGroup(i, weeklyValues[i])),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detailed Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildStatItem('Highest', highest > 0 ? '${highest.toStringAsFixed(0)} mg/dL' : '--', Colors.red),
                  _buildStatItem('Lowest', lowest > 0 ? '${lowest.toStringAsFixed(0)} mg/dL' : '--', Colors.green),
                  _buildStatItem('In Target', inTargetPercentage > 0 ? '$inTargetPercentage%' : '--', AppTheme.primaryRed),
                ],
              ),
            ),
            // Export Section - Now functional
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Download report as PDF', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _exportToPDF,  // Now calls the export function
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
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
        tooltip: 'Add Blood Sugar Reading',
      ),
    );
  }

  // _buildBarGroup, _buildSummaryCard, _buildStatItem remain unchanged...
  BarChartGroupData _buildBarGroup(int x, double value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value > 0 ? value : 0,
          color: value > 0 ? AppTheme.primaryRed : Colors.grey.withOpacity(0.2),
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, String unit, IconData icon) {
    // unchanged
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.grey , spreadRadius: 2, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 32),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    // unchanged
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}