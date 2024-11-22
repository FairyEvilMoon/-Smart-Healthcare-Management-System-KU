import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:healthcare_ku/models/medical_record_model.dart';
import 'package:healthcare_ku/screens/dashboard/patient/medical_records/add_medical_record_screen.dart';
import 'package:healthcare_ku/services/medical_record_service.dart';
import 'package:healthcare_ku/services/pdf_service.dart';

class ViewMedicalRecordsScreen extends StatefulWidget {
  final String patientId;

  const ViewMedicalRecordsScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  _ViewMedicalRecordsScreenState createState() =>
      _ViewMedicalRecordsScreenState();
}

class _ViewMedicalRecordsScreenState extends State<ViewMedicalRecordsScreen> {
  final MedicalRecordService _recordService = MedicalRecordService();
  final PDFService _pdfService = PDFService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
      ),
      body: StreamBuilder<List<MedicalRecord>>(
        stream: _recordService.getPatientMedicalRecords(widget.patientId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No medical records found'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final record = snapshot.data![index];
              return MedicalRecordCard(
                record: record,
                onDownload: () => _downloadPDF(record),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMedicalRecordScreen(
                patientId: widget.patientId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _downloadBytes(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName;
    anchor.click();
    html.Url.revokeObjectUrl(url);
  }

// In your medical_records_screen.dart
  Future<void> _downloadPDF(MedicalRecord record) async {
    try {
      final pdfService = PDFService();
      final Uint8List bytes = await pdfService.generatePDF(record);
      _downloadBytes(bytes, "medical_record_${record.id}.pdf");
    } catch (e) {
      print('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class MedicalRecordCard extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback onDownload;

  const MedicalRecordCard({
    Key? key,
    required this.record,
    required this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text('Date: ${record.dateCreated.toString().split(' ')[0]}'),
        subtitle: Text('Diagnosis: ${record.diagnosis}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Doctor: Doctor not found'), // Changed from doctorId
                const SizedBox(height: 8),
                Text('Symptoms: ${record.symptoms}'),
                const SizedBox(height: 8),
                if (record.prescriptions.isNotEmpty) ...[
                  const Text(
                    'Prescriptions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...record.prescriptions.map(
                    (prescription) => ListTile(
                      title: Text(prescription.medication),
                      subtitle: Text(
                        '${prescription.dosage} - ${prescription.frequency}',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download),
                      label: const Text('Download PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
