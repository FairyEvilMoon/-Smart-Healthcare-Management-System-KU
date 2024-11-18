import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthcare_system_ku/providers/auth_provider.dart';
import 'package:healthcare_system_ku/services/auth_service.dart';
import 'package:intl/intl.dart';
import '../../models/patient_model.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final patientAsyncValue = ref.watch(userProvider(user?.uid ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Portal'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: patientAsyncValue.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (PatientModel? patient) {
          if (patient == null) return Center(child: Text('Patient not found'));

          return IndexedStack(
            index: _selectedIndex,
            children: [
              _buildDashboard(patient),
              _buildAppointments(patient),
              _buildHealthRecords(patient),
              _buildProfile(patient),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildDashboard(PatientModel patient) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${patient.name}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 24),
          _buildUpcomingAppointment(patient),
          SizedBox(height: 24),
          _buildVitalSigns(patient),
          SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointment(PatientModel patient) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: AppointmentService().getPatientUpcomingAppointments(patient.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error loading appointments');
        if (!snapshot.hasData) return CircularProgressIndicator();

        final appointments = snapshot.data!;
        if (appointments.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Upcoming Appointments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorListScreen(),
                      ),
                    ),
                    child: Text('Book Appointment'),
                  ),
                ],
              ),
            ),
          );
        }

        final nextAppointment = appointments.first;
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Appointment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text(DateFormat('EEEE, MMMM d, y')
                      .format(nextAppointment.dateTime)),
                  subtitle: Text(
                      DateFormat('h:mm a').format(nextAppointment.dateTime)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVitalSigns(PatientModel patient) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Vital Signs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildVitalSignTile(
              'Heart Rate',
              '${patient.vitalSigns['heartRate'] ?? 'N/A'} bpm',
              Icons.favorite,
            ),
            _buildVitalSignTile(
              'Blood Pressure',
              patient.vitalSigns['bloodPressure'] ?? 'N/A',
              Icons.speed,
            ),
            _buildVitalSignTile(
              'Temperature',
              '${patient.vitalSigns['temperature'] ?? 'N/A'} °F',
              Icons.thermostat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildActionButton(
                  'Book\nAppointment',
                  Icons.add_circle,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorListScreen(),
                    ),
                  ),
                ),
                _buildActionButton(
                  'View\nPrescriptions',
                  Icons.medical_services,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrescriptionsScreen(),
                    ),
                  ),
                ),
                _buildActionButton(
                  'Medical\nHistory',
                  Icons.history,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicalHistoryScreen(),
                    ),
                  ),
                ),
                _buildActionButton(
                  'Emergency\nContacts',
                  Icons.emergency,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmergencyContactsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(16),
        minimumSize: Size(100, 100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
