import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare_ku/models/health_metric_model.dart';
import 'package:healthcare_ku/models/medical_record_model.dart';
import 'package:healthcare_ku/models/patient_model.dart';
import 'package:healthcare_ku/screens/dashboard/doctor/patient_details/add_clinical_notes_screen.dart';
import 'package:healthcare_ku/screens/dashboard/doctor/patient_details/add_prescription_screen.dart';
import 'package:healthcare_ku/screens/dashboard/doctor/patient_details/doctor_health_metric_view.dart';
import 'package:healthcare_ku/screens/dashboard/doctor/patient_details/doctor_scheduler_screen.dart';
import 'package:healthcare_ku/screens/dashboard/patient/medical_records/add_medical_record_screen.dart';

import 'package:intl/intl.dart';

class PatientDetailsScreen extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailsScreen({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Records'),
            Tab(text: 'Metrics'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.note_add),
            onPressed: () => _addMedicalRecord(context),
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMedicalRecordsTab(),
          _buildHealthMetricsTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scheduleAppointment(context),
        label: Text('Schedule Appointment'),
        icon: Icon(Icons.calendar_today),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientHeader(),
          SizedBox(height: 24),
          _buildInfoSection('Personal Information'),
          _buildInfoSection('Medical History'),
          _buildInfoSection('Allergies'),
          _buildInfoSection('Emergency Contact'),
        ],
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.patient.profileImageUrl != null
                  ? NetworkImage(widget.patient.profileImageUrl!)
                  : null,
              child: widget.patient.profileImageUrl == null
                  ? Text(
                      widget.patient.name
                          .split(' ')
                          .take(2)
                          .map((e) => e[0])
                          .join('')
                          .toUpperCase(),
                      style: TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            SizedBox(height: 16),
            Text(
              widget.patient.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              'Blood Group: ${widget.patient.bloodGroup}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(
                  icon: Icons.note_add,
                  label: 'Add Record',
                  onTap: () => _addMedicalRecord(context),
                ),
                _buildQuickAction(
                  icon: Icons.medication,
                  label: 'Prescribe',
                  onTap: () => _prescribeMedication(context),
                ),
                _buildQuickAction(
                  icon: Icons.history_edu,
                  label: 'Notes',
                  onTap: () => _addClinicalNotes(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            // Add specific content based on section
            if (title == 'Allergies')
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.patient.allergies
                    .map((allergy) => Chip(label: Text(allergy)))
                    .toList(),
              ),
            if (title == 'Medical History')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.patient.medicalHistory
                    .map((history) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('• $history'),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRecordsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medical_records')
          .where('patientId', isEqualTo: widget.patient.uid)
          .orderBy('dateCreated', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!.docs
            .map((doc) => MedicalRecord.fromFirestore(doc))
            .toList();

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_information, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No medical records found'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _addMedicalRecord(context),
                  child: Text('Add Medical Record'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: records.length,
          padding: EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildMedicalRecordCard(record);
          },
        );
      },
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          DateFormat('MMM dd, yyyy').format(record.dateCreated),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(record.diagnosis),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecordSection('Symptoms', record.symptoms),
                _buildRecordSection('Treatment Plan', record.treatmentPlan),
                _buildRecordSection('Notes', record.notes),
                if (record.prescriptions.isNotEmpty)
                  _buildPrescriptionsSection(record.prescriptions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordSection(String title, String content) {
    if (content.isEmpty) return SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
        Text(content),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPrescriptionsSection(List<Prescription> prescriptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prescriptions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        ...prescriptions.map((prescription) => Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(prescription.medication),
                subtitle: Text(
                  '${prescription.dosage} - ${prescription.frequency}\n${prescription.instructions}',
                ),
                trailing: Text(
                  DateFormat('MMM dd').format(prescription.prescribedDate),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildHealthMetricsTab() {
    return DoctorHealthMetricsView(
      patientId: widget.patient.uid,
      patientName: widget.patient.name,
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: widget.patient.uid)
          .orderBy('dateTime', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data!.docs;

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No appointment history'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: appointments.length,
          padding: EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final appointment =
                appointments[index].data() as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(appointment['status']),
                  child: Icon(Icons.calendar_today, color: Colors.white),
                ),
                title: Text(
                  DateFormat('MMM dd, yyyy - HH:mm')
                      .format((appointment['dateTime'] as Timestamp).toDate()),
                ),
                subtitle:
                    Text(appointment['purpose'] ?? 'No purpose specified'),
                trailing: Chip(
                  label: Text(
                    appointment['status'].toString().toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(appointment['status']),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addMedicalRecord(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicalRecordScreen(
          patientId: widget.patient.uid,
        ),
      ),
    );
  }

  void _prescribeMedication(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPrescriptionScreen(
          patientId: widget.patient.uid,
          patientName: widget.patient.name,
        ),
      ),
    );
  }

  void _addClinicalNotes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddClinicalNotesScreen(
          patientId: widget.patient.uid,
          patientName: widget.patient.name,
        ),
      ),
    );
  }

  void _scheduleAppointment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorSchedulePatientScreen(
          doctorId: FirebaseAuth.instance.currentUser!.uid,
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Patient Information'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit patient screen
                },
              ),
              ListTile(
                leading: Icon(Icons.file_download),
                title: Text('Download Medical History'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement download functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Share Medical Records'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'scheduled':
      return Colors.blue;
    case 'cancelled':
      return Colors.red;
    case 'noshow':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}
