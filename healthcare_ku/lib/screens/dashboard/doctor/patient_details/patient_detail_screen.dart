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
import 'package:healthcare_ku/screens/dashboard/doctor/patient_details/edit_patient_info_screen.dart';
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
          SizedBox(height: 16),
          _buildPersonalInformation(),
          SizedBox(height: 16),
          _buildMedicalInformation(),
          SizedBox(height: 16),
          _buildEmergencyContact(),
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
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: widget.patient.profileImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        widget.patient.profileImageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          widget.patient.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(fontSize: 36),
                        ),
                      ),
                    )
                  : Text(
                      widget.patient.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(fontSize: 36),
                    ),
            ),
            SizedBox(height: 16),
            Text(
              widget.patient.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Patient ID: ${widget.patient.uid}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickAction(
                  icon: Icons.edit,
                  label: 'Edit Info',
                  onTap: () => _editPatientInformation(),
                ),
                SizedBox(width: 24),
                _buildQuickAction(
                  icon: Icons.history,
                  label: 'History',
                  onTap: () {
                    if (_tabController.length > 3) {
                      _tabController.animateTo(3); // Switch to history tab
                    }
                  },
                ),
                SizedBox(width: 24),
                _buildQuickAction(
                  icon: Icons.medical_services,
                  label: 'Records',
                  onTap: () {
                    if (_tabController.length > 1) {
                      _tabController.animateTo(1); // Switch to records tab
                    }
                  },
                ),
                SizedBox(width: 24),
                _buildQuickAction(
                  icon: Icons.medication,
                  label: 'Prescription',
                  onTap: () => _prescribeMedication(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Personal Information',
              Icons.person,
            ),
            SizedBox(height: 16),
            _buildInfoRow('Full Name', widget.patient.name),
            _buildInfoRow('Email', widget.patient.email),
            if (widget.patient.phoneNumber != null)
              _buildInfoRow('Phone', widget.patient.phoneNumber!),
            _buildInfoRow(
              'Blood Group',
              widget.patient.bloodGroup.isEmpty
                  ? 'Not specified'
                  : widget.patient.bloodGroup,
            ),
            _buildInfoRow(
              'Status',
              widget.patient.status.toUpperCase(),
              valueColor: _getStatusColor(widget.patient.status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInformation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Medical Information',
              Icons.medical_information,
            ),
            SizedBox(height: 16),
            if (widget.patient.allergies.isNotEmpty) ...[
              Text(
                'Allergies',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.patient.allergies.map((allergy) {
                  return Chip(
                    label: Text(allergy),
                    backgroundColor: Colors.red[100],
                    labelStyle: TextStyle(color: Colors.red[900]),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
            ],
            if (widget.patient.medicalHistory.isNotEmpty) ...[
              Text(
                'Medical History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              ...widget.patient.medicalHistory.map((history) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(history),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContact() {
    if (widget.patient.emergencyContact.isEmpty) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Emergency Contact',
              Icons.emergency,
            ),
            SizedBox(height: 16),
            _buildInfoRow('Contact Number', widget.patient.emergencyContact),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _editPatientInformation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPatientInformationScreen(
          patient: widget.patient,
        ),
      ),
    ).then((_) {
      // Refresh the data when returning from edit screen
      setState(() {});
    });
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditPatientInformationScreen(
                              patient: PatientModel(
                                  uid: widget.patient.uid,
                                  email: widget.patient.email,
                                  name: widget.patient.name))));
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
