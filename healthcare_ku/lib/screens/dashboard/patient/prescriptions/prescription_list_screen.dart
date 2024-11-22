import 'package:flutter/material.dart';
import 'package:healthcare_ku/models/prescription_model.dart';
import 'package:healthcare_ku/screens/dashboard/patient/prescriptions/prescription_detail_screen.dart';
import 'package:healthcare_ku/services/prescription_service.dart';
import 'package:healthcare_ku/widgets/prescription_card.dart';

class PrescriptionListScreen extends StatelessWidget {
  final String patientId;
  final PrescriptionService _prescriptionService = PrescriptionService();

  PrescriptionListScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
      ),
      body: StreamBuilder<List<PrescriptionModel>>(
        stream: _prescriptionService.getPrescriptionsForPatient(patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final prescriptions = snapshot.data ?? [];

          if (prescriptions.isEmpty) {
            return const Center(
              child: Text('No prescriptions found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              return PrescriptionCard(
                prescription: prescriptions[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrescriptionDetailScreen(
                        prescriptionId: prescriptions[index].id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
