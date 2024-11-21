import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/firebase_service.dart';
import '../../../../models/health_metric.dart';

class AddHealthMetricScreen extends StatefulWidget {
  @override
  _AddHealthMetricScreenState createState() => _AddHealthMetricScreenState();
}

class _AddHealthMetricScreenState extends State<AddHealthMetricScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();

  double? heartRate;
  double? systolicPressure;
  double? diastolicPressure;
  double? weight;

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (double.tryParse(value) == null) return 'Must be a number';
    return null;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final metric = HealthMetric(
        heartRate: heartRate!,
        systolicPressure: systolicPressure!,
        diastolicPressure: diastolicPressure!,
        weight: weight!,
        timestamp: DateTime.now(),
      );

      try {
        await _firebaseService.addHealthMetric(
            FirebaseAuth.instance.currentUser!.uid, metric);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving metrics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Health Metrics')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: InputDecoration(
                  labelText: 'Heart Rate',
                  helperText: 'Beats per minute',
                  suffixText: 'bpm'),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onSaved: (value) => heartRate = double.parse(value!),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                  labelText: 'Systolic Pressure',
                  helperText: 'Upper number',
                  suffixText: 'mmHg'),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onSaved: (value) => systolicPressure = double.parse(value!),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                  labelText: 'Diastolic Pressure',
                  helperText: 'Lower number',
                  suffixText: 'mmHg'),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onSaved: (value) => diastolicPressure = double.parse(value!),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration:
                  InputDecoration(labelText: 'Weight', suffixText: 'kg'),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onSaved: (value) => weight = double.parse(value!),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text('Save Metrics'),
            ),
          ],
        ),
      ),
    );
  }
}
