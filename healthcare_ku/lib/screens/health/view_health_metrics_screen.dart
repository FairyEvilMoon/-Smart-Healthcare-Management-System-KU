import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../models/health_metric.dart';
import 'add_health_metric_screen.dart';

class ViewHealthMetricsScreen extends StatefulWidget {
  @override
  _ViewHealthMetricsScreenState createState() =>
      _ViewHealthMetricsScreenState();
}

class _ViewHealthMetricsScreenState extends State<ViewHealthMetricsScreen> {
  final _firebaseService = FirebaseService();
  List<HealthMetric> metrics = [];

  void _refreshMetrics() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final newMetrics = await _firebaseService.getPatientHealthMetrics(userId);
    setState(() {
      metrics = newMetrics;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshMetrics();
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Heart Rate', Colors.blue),
        SizedBox(width: 20),
        _legendItem('Blood Pressure', Colors.red),
        SizedBox(width: 20),
        _legendItem('Weight', Colors.green),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reversedMetrics = metrics.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text('Health Metrics History')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildLegend(),
          SizedBox(height: 20),
          Container(
            height: 300,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    maxContentWidth: 200,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: EdgeInsets.all(8),
                    tooltipBorder: BorderSide(color: Colors.black12),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        String label = '';
                        if (spot.barIndex == 0)
                          label = 'HR: ${spot.y.toStringAsFixed(1)} bpm';
                        if (spot.barIndex == 1)
                          label = 'BP: ${spot.y.toStringAsFixed(1)} mmHg';
                        if (spot.barIndex == 2)
                          label = 'Weight: ${spot.y.toStringAsFixed(1)} kg';
                        return LineTooltipItem(
                          label,
                          TextStyle(color: Colors.black),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < reversedMetrics.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${reversedMetrics[value.toInt()].timestamp.month}/${reversedMetrics[value.toInt()].timestamp.day}',
                              style: TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: reversedMetrics.asMap().entries.map((entry) {
                      return FlSpot(
                          entry.key.toDouble(), entry.value.heartRate);
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: reversedMetrics.asMap().entries.map((entry) {
                      return FlSpot(
                          entry.key.toDouble(), entry.value.systolicPressure);
                    }).toList(),
                    isCurved: true,
                    color: Colors.red,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: reversedMetrics.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.weight);
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: reversedMetrics.length,
            itemBuilder: (context, index) {
              final metric = reversedMetrics[index];
              return Card(
                child: ListTile(
                  title: Text(
                    'Date: ${metric.timestamp.toString().split('.')[0]}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Heart Rate: ${metric.heartRate} bpm'),
                      Text(
                          'Blood Pressure: ${metric.systolicPressure}/${metric.diastolicPressure} mmHg'),
                      Text('Weight: ${metric.weight} kg'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddHealthMetricScreen()),
          );
          _refreshMetrics();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
