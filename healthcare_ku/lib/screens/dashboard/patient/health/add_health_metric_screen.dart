import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/firebase_service.dart';
import 'package:healthcare_ku/models/health_metric_model.dart';

class AddHealthMetricScreen extends StatefulWidget {
  final String patientId; // Add patient ID parameter

  const AddHealthMetricScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  _AddHealthMetricScreenState createState() => _AddHealthMetricScreenState();
}

class _AddHealthMetricScreenState extends State<AddHealthMetricScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();
  bool _isLoading = false;

  double? heartRate;
  double? systolicPressure;
  double? diastolicPressure;
  double? weight;

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (double.tryParse(value) == null) return 'Must be a number';
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _formKey.currentState!.save();

      final metric = HealthMetric(
        patientId: widget.patientId,
        doctorId: FirebaseAuth.instance.currentUser!.uid,
        heartRate: heartRate!,
        systolicPressure: systolicPressure!,
        diastolicPressure: diastolicPressure!,
        weight: weight!,
        timestamp: DateTime.now(),
      );

      await _firebaseService.addHealthMetric(widget.patientId, metric);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health metrics saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving metrics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Health Metrics')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Heart Rate',
                  helperText: 'Beats per minute',
                  suffixText: 'bpm'),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onSaved: (value) => heartRate = double.parse(value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Systolic Pressure',
                  helperText: 'Upper number',
                  suffixText: 'mmHg'),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onSaved: (value) => systolicPressure = double.parse(value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Diastolic Pressure',
                  helperText: 'Lower number',
                  suffixText: 'mmHg'),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onSaved: (value) => diastolicPressure = double.parse(value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration:
                  const InputDecoration(labelText: 'Weight', suffixText: 'kg'),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onSaved: (value) => weight = double.parse(value!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Metrics'),
            ),
          ],
        ),
      ),
    );
  }
}
