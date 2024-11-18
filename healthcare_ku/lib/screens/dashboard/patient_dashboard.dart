// lib/screens/dashboard/patient_dashboard.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient_model.dart';
import '../../services/firebase_service.dart';

class PatientDashboard extends StatefulWidget {
  final PatientModel patient;

  PatientDashboard({required this.patient});

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/book-appointment');
        },
        label: Text('Book Appointment'),
        icon: Icon(Icons.add),
      ),
    );
  }

  Widget _buildWelcomeCard() {
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
                _buildStatusItem(
                  'Next Appointment',
                  'Today, 2:30 PM',
                  Icons.calendar_today,
                ),
                _buildStatusItem(
                  'Medications',
                  '2 pending',
                  Icons.medical_services,
                ),
                _buildStatusItem(
                  'Reports',
                  '3 new',
                  Icons.description,
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
        'label': 'Appointments',
        'route': '/appointments'
      },
      {
        'icon': Icons.medication,
        'label': 'Medications',
        'route': '/medications'
      },
      {
        'icon': Icons.favorite,
        'label': 'Health Metrics',
        'route': '/health-metrics'
      },
      {
        'icon': Icons.description,
        'label': 'Medical Records',
        'route': '/medical-records'
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
            onTap: () {
              Navigator.pushNamed(context, action['route'] as String);
            },
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
                    Navigator.pushNamed(context, '/appointments');
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 2, // Show only next 2 appointments
              itemBuilder: (context, index) {
                return Card(
                  elevation: 1,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.medical_services),
                    ),
                    title: Text('Dr. John Doe'),
                    subtitle: Text('General Checkup'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Tomorrow'),
                        Text('10:00 AM'),
                      ],
                    ),
                    onTap: () {
                      // View appointment details
                    },
                  ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Health Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/health-metrics');
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard(
                  'Heart Rate',
                  '72',
                  'bpm',
                  Icons.favorite,
                  Colors.red,
                ),
                _buildMetricCard(
                  'Blood Pressure',
                  '120/80',
                  'mmHg',
                  Icons.speed,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Weight',
                  '70',
                  'kg',
                  Icons.monitor_weight,
                  Colors.green,
                ),
              ],
            ),
          ],
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
                    Navigator.pushNamed(context, '/prescriptions');
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 2,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 1,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.medication),
                    title: Text('Prescription #${index + 1}'),
                    subtitle: Text(
                        'Dr. Jane Smith • ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // View prescription details
                    },
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
