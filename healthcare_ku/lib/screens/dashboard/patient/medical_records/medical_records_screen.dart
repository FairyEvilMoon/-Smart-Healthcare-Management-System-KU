import 'package:flutter/material.dart';
import 'package:healthcare_ku/models/medical_record_model.dart';
import 'package:healthcare_ku/screens/dashboard/patient/medical_records/add_medical_record_screen.dart';
import 'package:healthcare_ku/services/medical_record_service.dart';
import 'package:healthcare_ku/services/pdf_service';

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

  Future<void> _downloadPDF(MedicalRecord record) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final file = await _pdfService.generateMedicalRecordPDF(record);
      Navigator.pop(context); // Dismiss loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF generated successfully'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _pdfService.sharePDF(file),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
        ),
      );
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
                Text('Doctor ID: ${record.doctorId}'),
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
