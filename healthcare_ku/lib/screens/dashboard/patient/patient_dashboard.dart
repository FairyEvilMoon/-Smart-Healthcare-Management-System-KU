// lib/screens/dashboard/patient_dashboard.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthcare_ku/models/appointment_model.dart';
import 'package:healthcare_ku/models/health_metric.dart';
import 'package:healthcare_ku/models/medical_record_model.dart';
import 'package:healthcare_ku/models/prescription_model.dart';
import 'package:healthcare_ku/screens/dashboard/patient/appointments/book_appointment_screen.dart';
import 'package:healthcare_ku/screens/dashboard/patient/appointments/upcoming_appointments_screen.dart';
import 'package:healthcare_ku/screens/dashboard/patient/health/view_health_metrics_screen.dart';
import 'package:healthcare_ku/screens/dashboard/patient/medical_records/medical_records_screen.dart';
import 'package:healthcare_ku/screens/dashboard/patient/prescriptions/prescription_detail_screen.dart';
import 'package:healthcare_ku/screens/dashboard/patient/prescriptions/prescription_list_screen.dart';
import 'package:healthcare_ku/services/appointment_service.dart';
import 'package:healthcare_ku/services/health_metrics_service.dart';
import 'package:healthcare_ku/services/medical_record_service.dart';
import 'package:healthcare_ku/services/prescription_service.dart';
import 'package:intl/intl.dart';
import '../../../models/patient_model.dart';
import '../../../services/firebase_service.dart';

class PatientDashboard extends StatefulWidget {
  final PatientModel patient;

  PatientDashboard({required this.patient, Key? key});

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _handleSignOut() async {
    try {
      // Show confirmation dialog
      final shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Sign Out'),
            content: Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (shouldSignOut == true) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        await _firebaseService.signOut();

        // Pop loading dialog and navigate to login
        Navigator.of(context).pop();
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Handle any errors
      Navigator.of(context).pop(); // Pop loading dialog if it's showing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.person),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'signout':
                  _handleSignOut();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh dashboard data
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              SizedBox(height: 16),
              _buildQuickActions(),
              SizedBox(height: 16),
              _buildUpcomingAppointments(),
              SizedBox(height: 16),
              _buildHealthMetrics(),
              SizedBox(height: 16),
              _buildRecentPrescriptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final PrescriptionService _prescriptionService = PrescriptionService();
    final MedicalRecordService _medicalRecordService = MedicalRecordService();

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.patient.profileImageUrl != null
                      ? NetworkImage(widget.patient.profileImageUrl!)
                      : null,
                  child: widget.patient.profileImageUrl == null
                      ? Icon(Icons.person, size: 30)
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        widget.patient.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StreamBuilder<List<AppointmentModel>>(
                  stream: AppointmentService()
                      .getUpcomingAppointments(widget.patient.uid),
                  builder: (context, snapshot) {
                    String appointmentText = 'No upcoming';
                    String timeText = 'appointments';

                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      final nextAppointment = snapshot.data!.first;
                      appointmentText = 'Next Appointment';
                      timeText = DateFormat('MMM d, h:mm a')
                          .format(nextAppointment.dateTime);
                    }

                    return _buildStatusItem(
                      appointmentText,
                      timeText,
                      Icons.calendar_today,
                    );
                  },
                ),
                StreamBuilder<List<PrescriptionModel>>(
                  stream: _prescriptionService
                      .getPrescriptionsForPatient(widget.patient.uid),
                  builder: (context, snapshot) {
                    int activeMedications = 0;
                    if (snapshot.hasData) {
                      activeMedications = snapshot.data!
                          .where(
                              (prescription) => prescription.status == 'Active')
                          .fold(
                              0,
                              (sum, prescription) =>
                                  sum + prescription.medications.length);
                    }

                    return _buildStatusItem(
                      'Medications',
                      '$activeMedications pending',
                      Icons.medical_services,
                    );
                  },
                ),
                StreamBuilder<List<MedicalRecord>>(
                  stream: _medicalRecordService
                      .getPatientMedicalRecords(widget.patient.uid),
                  builder: (context, snapshot) {
                    String reportText = '0 reports';
                    if (snapshot.hasData) {
                      final int recordCount = snapshot.data!.length;
                      reportText =
                          '$recordCount report${recordCount != 1 ? 's' : ''}';
                    } else if (snapshot.hasError) {
                      reportText = 'Error';
                    }

                    return _buildStatusItem(
                      'Reports',
                      reportText,
                      Icons.description,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.calendar_today,
        'label': 'Book Appointments',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookAppointmentScreen(
                patientId: widget.patient.uid,
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.medication,
        'label': 'Medications',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionListScreen(
                patientId: widget.patient.uid, // Replace with actual patient ID
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.favorite,
        'label': 'Health Metrics',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ViewHealthMetricsScreen()),
          );
        },
      },
      {
        'icon': Icons.description,
        'label': 'Medical Records',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewMedicalRecordsScreen(
                patientId: 'widget.patient.uid',
              ),
            ),
          );
        },
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: actions.map((action) {
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: action['onTap'] as Function(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action['icon'] as IconData,
                  size: 32,
                  color: Colors.blue,
                ),
                SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Appointments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpcomingAppointmentsScreen(
                          patientId: widget.patient.uid,
                        ),
                      ),
                    );
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 8),
            StreamBuilder<List<AppointmentModel>>(
              stream: AppointmentService()
                  .getUpcomingAppointments(widget.patient.uid),
              builder: (context, snapshot) {
                print("Patient ID: ${widget.patient.uid}");
                print("Data: ${snapshot.data}");
                print("Error: ${snapshot.error}");

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final appointments = snapshot.data ?? [];

                if (appointments.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('No upcoming appointments'),
                    ),
                  );
                }

                return Column(
                  children: appointments
                      .take(2)
                      .map((appointment) => Card(
                            elevation: 1,
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(Icons.medical_services),
                              ),
                              title: Text(appointment.doctorName),
                              subtitle: Text(appointment.purpose),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    DateFormat('MMM d')
                                        .format(appointment.dateTime),
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    DateFormat('h:mm a')
                                        .format(appointment.dateTime),
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: StreamBuilder<List<HealthMetric>>(
          stream: HealthMetricsService().getPatientHealthMetricsStream(
              FirebaseAuth.instance.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error loading metrics: ${snapshot.error}');
            }

            final latestMetric =
                snapshot.data?.isNotEmpty == true ? snapshot.data!.first : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Health Metrics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {
                              // This will trigger a rebuild
                            });
                          },
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ViewHealthMetricsScreen()),
                            );
                            // The StreamBuilder will automatically update when returning
                          },
                          child: Text('View All'),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCard(
                      'Heart Rate',
                      latestMetric?.heartRate.toString() ?? '-',
                      'bpm',
                      Icons.favorite,
                      Colors.red,
                    ),
                    _buildMetricCard(
                      'Blood Pressure',
                      latestMetric != null
                          ? '${latestMetric.systolicPressure}/${latestMetric.diastolicPressure}'
                          : '-',
                      'mmHg',
                      Icons.speed,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      'Weight',
                      latestMetric?.weight.toString() ?? '-',
                      'kg',
                      Icons.monitor_weight,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, String unit, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          unit,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRecentPrescriptions() {
    final PrescriptionService _prescriptionService = PrescriptionService();

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Prescriptions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrescriptionListScreen(
                          patientId: widget.patient.uid,
                        ),
                      ),
                    );
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 8),
            StreamBuilder<List<PrescriptionModel>>(
              stream: _prescriptionService
                  .getPrescriptionsForPatient(widget.patient.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading prescriptions'));
                }

                final prescriptions = snapshot.data ?? [];
                if (prescriptions.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('No prescriptions found'),
                    ),
                  );
                }

                // Show only the 2 most recent prescriptions
                final recentPrescriptions = prescriptions.take(2).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: recentPrescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = recentPrescriptions[index];
                    return Card(
                      elevation: 1,
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          Icons.medication,
                          color: prescription.status == 'Active'
                              ? Colors.green
                              : Colors.grey,
                        ),
                        title: Text(
                          'Prescription #${prescription.id.substring(0, 8)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${prescription.doctorId}', // You might want to fetch doctor's name
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(prescription.prescriptionDate),
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: prescription.status == 'Active'
                                    ? Colors.green[100]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                prescription.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: prescription.status == 'Active'
                                      ? Colors.green[700]
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrescriptionDetailScreen(
                                prescriptionId: prescription.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
