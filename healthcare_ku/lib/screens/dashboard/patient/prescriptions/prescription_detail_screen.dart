import 'package:flutter/material.dart';
import 'package:healthcare_ku/models/prescription_model.dart';
import 'package:healthcare_ku/services/prescription_service.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final String prescriptionId;
  final PrescriptionService _prescriptionService = PrescriptionService();

  PrescriptionDetailScreen({Key? key, required this.prescriptionId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Details'),
      ),
      body: FutureBuilder<PrescriptionModel?>(
        future: _prescriptionService.getPrescriptionById(prescriptionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final prescription = snapshot.data;
          if (prescription == null) {
            return const Center(child: Text('Prescription not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard('Prescription Date',
                    prescription.prescriptionDate.toString().split(' ')[0]),
                const SizedBox(height: 16),
                _buildInfoCard('Status', prescription.status),
                const SizedBox(height: 16),
                _buildMedicationsList(prescription.medications),
                const SizedBox(height: 16),
                if (prescription.notes.isNotEmpty) ...[
                  _buildInfoCard('Notes', prescription.notes),
                  const SizedBox(height: 16),
                ],
                _buildInfoCard(
                    'End Date', prescription.endDate.toString().split(' ')[0]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsList(List<Medication> medications) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final medication = medications[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Dosage: ${medication.dosage}'),
                        Text('Frequency: ${medication.frequency}'),
                        Text('Instructions: ${medication.instructions}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
