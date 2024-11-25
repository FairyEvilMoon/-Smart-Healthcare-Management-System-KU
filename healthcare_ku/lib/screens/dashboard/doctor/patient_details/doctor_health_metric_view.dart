import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../models/health_metric_model.dart';
import '../../../../services/firebase_service.dart';

class DoctorHealthMetricsView extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DoctorHealthMetricsView({
    Key? key,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  @override
  _DoctorHealthMetricsViewState createState() =>
      _DoctorHealthMetricsViewState();
}

class _DoctorHealthMetricsViewState extends State<DoctorHealthMetricsView> {
  final _firebaseService = FirebaseService();
  List<HealthMetric> metrics = [];

  void _refreshMetrics() async {
    final newMetrics =
        await _firebaseService.getPatientHealthMetrics(widget.patientId);
    if (mounted) {
      setState(() {
        metrics = newMetrics;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshMetrics();
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _legendItem('Heart Rate', Colors.blue, 'bpm'),
            _legendItem('Blood Pressure', Colors.red, 'mmHg'),
            _legendItem('Weight', Colors.green, 'kg'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color, String unit) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              unit,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reversedMetrics = metrics.reversed.toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Metrics History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: _refreshMetrics,
                icon: Icon(Icons.refresh),
                label: Text('Refresh'),
              ),
            ],
          ),
        ),
        _buildLegend(),
        if (metrics.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_heart_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No health metrics recorded for this patient',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trends',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 16),
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
                                  tooltipBorder:
                                      BorderSide(color: Colors.black12),
                                  getTooltipItems:
                                      (List<LineBarSpot> touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      String label = '';
                                      if (spot.barIndex == 0)
                                        label =
                                            'HR: ${spot.y.toStringAsFixed(1)} bpm';
                                      if (spot.barIndex == 1)
                                        label =
                                            'BP: ${spot.y.toStringAsFixed(1)} mmHg';
                                      if (spot.barIndex == 2)
                                        label =
                                            'Weight: ${spot.y.toStringAsFixed(1)} kg';
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
                                          value.toInt() <
                                              reversedMetrics.length) {
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
                                border:
                                    Border.all(color: const Color(0xff37434d)),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: reversedMetrics
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    return FlSpot(entry.key.toDouble(),
                                        entry.value.heartRate);
                                  }).toList(),
                                  isCurved: true,
                                  color: Colors.blue,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  spots: reversedMetrics
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    return FlSpot(entry.key.toDouble(),
                                        entry.value.systolicPressure);
                                  }).toList(),
                                  isCurved: true,
                                  color: Colors.red,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  spots: reversedMetrics
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    return FlSpot(entry.key.toDouble(),
                                        entry.value.weight);
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
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Detailed Records',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: reversedMetrics.length,
                        itemBuilder: (context, index) {
                          final metric = reversedMetrics[index];
                          return ListTile(
                            title: Text(
                              metric.timestamp.toString().split('.')[0],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMetricRow(
                                  'Heart Rate',
                                  '${metric.heartRate} bpm',
                                  Icons.favorite,
                                  Colors.blue,
                                ),
                                _buildMetricRow(
                                  'Blood Pressure',
                                  '${metric.systolicPressure}/${metric.diastolicPressure} mmHg',
                                  Icons.speed,
                                  Colors.red,
                                ),
                                _buildMetricRow(
                                  'Weight',
                                  '${metric.weight} kg',
                                  Icons.monitor_weight,
                                  Colors.green,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMetricRow(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(value),
        ],
      ),
    );
  }
}
