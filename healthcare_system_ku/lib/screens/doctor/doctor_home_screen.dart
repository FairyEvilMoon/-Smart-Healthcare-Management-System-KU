import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthcare_system_ku/models/appointment_model.dart';
import 'package:healthcare_system_ku/models/doctor_model.dart';
import 'package:healthcare_system_ku/models/patient_model.dart';
import 'package:healthcare_system_ku/providers/auth_provider.dart';
import 'package:healthcare_system_ku/services/appointment_service.dart';
import 'package:healthcare_system_ku/services/auth_service.dart';

class DoctorHomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final doctorAsyncValue = ref.watch(userProvider(user?.uid ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Portal'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: doctorAsyncValue.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (DoctorModel? doctor) {
          if (doctor == null) return Center(child: Text('Doctor not found'));

          return IndexedStack(
            index: _selectedIndex,
            children: [
              _buildDashboard(doctor),
              _buildAppointments(doctor),
              _buildPatients(doctor),
              _buildProfile(doctor),
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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildDashboard(DoctorModel doctor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Dr. ${doctor.name}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 24),
          _buildTodaysAppointments(doctor),
          SizedBox(height: 24),
          _buildPatientStats(doctor),
          SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildTodaysAppointments(DoctorModel doctor) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: AppointmentService().getDoctorTodayAppointments(doctor.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error loading appointments');
        if (!snapshot.hasData) return CircularProgressIndicator();

        final appointments = snapshot.data!;
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Appointments",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                if (appointments.isEmpty)
                  Text('No appointments scheduled for today')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      return FutureBuilder<PatientModel?>(
                        future:
                            PatientService().getPatient(appointment.patientId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return ListTile(
                              title: Text('Loading...'),
                            );
                          }
                          final patient = snapshot.data!;
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(patient.name[0]),
                            ),
                            title: Text(patient.name),
                            subtitle: Text(DateFormat('h:mm a')
                                .format(appointment.dateTime)),
                            trailing:
                                _buildAppointmentStatus(appointment.status),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppointmentDetailsScreen(
                                  appointment: appointment,
                                  patient: patient,
                                ),
                              ),
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
      },
    );
  }

  Widget _buildAppointmentStatus(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPatientStats(DoctorModel doctor) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Patients',
                    '${doctor.patientCount ?? 0}',
                    Icons.people,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Today',
                    '${doctor.todayAppointments ?? 0}',
                    Icons.today,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
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
                  'View\nSchedule',
                  Icons.calendar_month,
                  () => setState(() => _selectedIndex = 1),
                ),
                _buildActionButton(
                  'Patient\nRecords',
                  Icons.folder_shared,
                  () => setState(() => _selectedIndex = 2),
                ),
                _buildActionButton(
                  'Write\nPrescription',
                  Icons.medical_services,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrescriptionFormScreen(),
                    ),
                  ),
                ),
                _buildActionButton(
                  'Update\nAvailability',
                  Icons.access_time,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateAvailabilityScreen(),
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

  Widget _buildAppointments(DoctorModel doctor) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAppointmentsList(doctor, 'upcoming'),
                _buildAppointmentsList(doctor, 'completed'),
                _buildAppointmentsList(doctor, 'cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(DoctorModel doctor, String type) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: AppointmentService().getDoctorAppointmentsByStatus(
        doctor.uid,
        type == 'upcoming' ? ['pending', 'confirmed'] : [type],
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading appointments'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data!;
        if (appointments.isEmpty) {
          return Center(child: Text('No $type appointments'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return FutureBuilder<PatientModel?>(
              future: PatientService().getPatient(appointment.patientId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Card(
                    child: ListTile(
                      title: Text('Loading...'),
                    ),
                  );
                }

                final patient = snapshot.data!;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(patient.name[0]),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    title: Text(patient.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('EEEE, MMMM d, y')
                            .format(appointment.dateTime)),
                        Text(DateFormat('h:mm a').format(appointment.dateTime)),
                      ],
                    ),
                    trailing: type == 'upcoming'
                        ? PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'confirm',
                                child: Text('Confirm'),
                              ),
                              PopupMenuItem(
                                value: 'cancel',
                                child: Text('Cancel'),
                              ),
                            ],
                            onSelected: (value) async {
                              switch (value) {
                                case 'confirm':
                                  await AppointmentService()
                                      .updateAppointmentStatus(
                                    appointment.id,
                                    'confirmed',
                                  );
                                  break;
                                case 'cancel':
                                  await AppointmentService()
                                      .updateAppointmentStatus(
                                    appointment.id,
                                    'cancelled',
                                  );
                                  break;
                              }
                            },
                          )
                        : _buildAppointmentStatus(appointment.status),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetailsScreen(
                          appointment: appointment,
                          patient: patient,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPatients(DoctorModel doctor) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              // Implement patient search
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<PatientModel>>(
            stream: PatientService().getDoctorPatients(doctor.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error loading patients'));
              }

              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final patients = snapshot.data!;
              if (patients.isEmpty) {
                return Center(child: Text('No patients found'));
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(patient.name[0]),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      title: Text(patient.name),
                      subtitle: Text(patient.phoneNumber),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientDetailsScreen(
                            patient: patient,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfile(DoctorModel doctor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: doctor.profileImageUrl != null
                      ? NetworkImage(doctor.profileImageUrl!)
                      : null,
                  child: doctor.profileImageUrl == null
                      ? Text(
                          doctor.name[0],
                          style: TextStyle(fontSize: 32),
                        )
                      : null,
                ),
                SizedBox(height: 16),
                Text(
                  'Dr. ${doctor.name}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  doctor.specialization,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          _buildProfileSection(
            'Personal Information',
            [
              _buildProfileItem('Email', doctor.email, Icons.email),
              _buildProfileItem('Phone', doctor.phoneNumber, Icons.phone),
              _buildProfileItem('License', doctor.licenseNumber, Icons.badge),
            ],
          ),
          SizedBox(height: 16),
          _buildProfileSection(
            'Qualifications',
            doctor.qualifications
                .map((q) => _buildProfileItem('•', q, Icons.school))
                .toList(),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditDoctorProfileScreen(
                  doctor: doctor,
                ),
              ),
            ),
            child: Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> items) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != '•')
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
