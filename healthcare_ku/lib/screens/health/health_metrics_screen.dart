import 'package:flutter/material.dart';
import 'package:healthcare_ku/screens/health/health_metrics_chart_view.dart';
import '../../models/health_metric.dart';
import '../../services/firebase_service.dart';
import 'package:intl/intl.dart';

class HealthMetricsScreen extends StatefulWidget {
  @override
  _HealthMetricsScreenState createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends State<HealthMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();

  final _heartRateController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitHealthMetrics() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final metric = HealthMetric(
        timestamp: DateTime.now(),
        heartRate: double.parse(_heartRateController.text),
        systolicPressure: double.parse(_systolicController.text),
        diastolicPressure: double.parse(_diastolicController.text),
      );

      await _firebaseService.addHealthMetric('current-user-id', metric);

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Health metrics updated successfully')),
      );

      _resetForm();
    }
  }

  void _resetForm() {
    _heartRateController.clear();
    _systolicController.clear();
    _diastolicController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Metrics'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMetricsForm(),
              SizedBox(height: 24),
              _buildMetricsHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter New Measurements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _heartRateController,
                decoration: InputDecoration(
                  labelText: 'Heart Rate (bpm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter heart rate';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Please enter a valid heart rate';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _systolicController,
                      decoration: InputDecoration(
                        labelText: 'Systolic Pressure',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final number = double.tryParse(value);
                        if (number == null || number <= 0) {
                          return 'Invalid value';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _diastolicController,
                      decoration: InputDecoration(
                        labelText: 'Diastolic Pressure',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final number = double.tryParse(value);
                        if (number == null || number <= 0) {
                          return 'Invalid value';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitHealthMetrics,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Save Measurements'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsHistory() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Metrics History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            FutureBuilder<List<HealthMetric>>(
              future:
                  _firebaseService.getPatientHealthMetrics('current-user-id'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.timeline_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No health metrics recorded yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Prepare data for the chart
                final chartData = snapshot.data!.map((metric) {
                  return {
                    'timestamp': DateFormat('MM/dd').format(metric.timestamp),
                    'heartRate': metric.heartRate,
                    'systolicPressure': metric.systolicPressure,
                    'diastolicPressure': metric.diastolicPressure,
                  };
                }).toList();

                return Column(
                  children: [
                    // Chart Section
                    Container(
                      height: 300,
                      padding: EdgeInsets.all(8.0),
                      child: HealthMetricsChartView(data: chartData),
                    ),
                    Divider(height: 32),

                    // Statistics Section
                    _buildStatistics(snapshot.data!),
                    Divider(height: 32),

                    // Detailed List Section
                    Text(
                      'Detailed Records',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final metric = snapshot.data![index];
                        return Card(
                          elevation: 1,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              DateFormat('MMM dd, yyyy HH:mm')
                                  .format(metric.timestamp),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildMetricItem(
                                      'Heart Rate',
                                      '${metric.heartRate.round()} bpm',
                                    ),
                                    SizedBox(width: 16),
                                    _buildMetricItem(
                                      'Blood Pressure',
                                      '${metric.systolicPressure.round()}/${metric.diastolicPressure.round()}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.more_vert),
                              onPressed: () {
                                // Show options menu
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) =>
                                      _buildMetricOptions(metric),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(List<HealthMetric> metrics) {
    final avgHeartRate =
        metrics.map((m) => m.heartRate).reduce((a, b) => a + b) /
            metrics.length;
    final avgSystolic =
        metrics.map((m) => m.systolicPressure).reduce((a, b) => a + b) /
            metrics.length;
    final avgDiastolic =
        metrics.map((m) => m.diastolicPressure).reduce((a, b) => a + b) /
            metrics.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average Readings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard(
              'Heart Rate',
              '${avgHeartRate.round()}',
              'bpm',
              Icons.favorite,
              Colors.red,
            ),
            _buildStatCard(
              'Blood Pressure',
              '${avgSystolic.round()}/${avgDiastolic.round()}',
              'mmHg',
              Icons.speed,
              Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String unit, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricOptions(HealthMetric metric) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Share'),
            onTap: () {
              // Implement share functionality
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
            onTap: () {
              // Implement delete functionality
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }
}
