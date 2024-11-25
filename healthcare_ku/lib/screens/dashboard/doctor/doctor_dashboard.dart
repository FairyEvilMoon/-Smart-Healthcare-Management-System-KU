import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:healthcare_ku/models/appointment_model.dart';
import 'package:healthcare_ku/models/availability_slot_model.dart';
import 'package:healthcare_ku/models/patient_model.dart';
import 'package:healthcare_ku/screens/dashboard/doctor/availability/manage_availability_screen.dart';
import 'package:healthcare_ku/screens/dashboard/doctor/patient_details/patient_card.dart';
import 'package:healthcare_ku/screens/dashboard/doctor/patient_details/patient_detail_screen.dart';
import 'package:healthcare_ku/services/appointment_service.dart';
import 'package:healthcare_ku/services/availability_service.dart';
import 'package:healthcare_ku/widgets/data_selector.dart';
import 'package:intl/intl.dart';
import '../../../models/doctor_model.dart';
import '../../../services/firebase_service.dart';

class DoctorDashboard extends StatefulWidget {
  final DoctorModel doctor;

  DoctorDashboard({required this.doctor});

  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  DateTime? _selectedDate;
  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

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
        title: Text('Doctor Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Today'),
            Tab(text: 'Patients'),
            Tab(text: 'Schedule'),
          ],
        ),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayView(),
          _buildPatientsView(),
          _buildScheduleView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add new appointment or patient
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildActionSheet(),
          );
        },
        label: Text('Add New'),
        icon: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayView() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoctorStats(startOfDay, endOfDay),
            SizedBox(height: 24),
            _buildTodayAppointments(startOfDay, endOfDay),
            SizedBox(height: 24),
            _buildPendingTasks(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorStats(DateTime startOfDay, DateTime endOfDay) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor.uid)
          .where('dateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snapshot) {
        int totalAppointments = 0;
        int completedAppointments = 0;
        int pendingAppointments = 0;

        if (snapshot.hasData) {
          final appointments = snapshot.data!.docs;
          totalAppointments = appointments.length;
          completedAppointments =
              appointments.where((doc) => doc['status'] == 'completed').length;
          pendingAppointments =
              appointments.where((doc) => doc['status'] == 'scheduled').length;
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: widget.doctor.profileImageUrl != null
                          ? NetworkImage(widget.doctor.profileImageUrl!)
                          : null,
                      child: widget.doctor.profileImageUrl == null
                          ? Icon(Icons.person, size: 30)
                          : null,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${widget.doctor.name}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            widget.doctor.specialization ?? 'Specialization',
                            style: Theme.of(context).textTheme.bodyMedium,
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
                    _buildStatItem(
                      'Today\'s\nAppointments',
                      totalAppointments.toString(),
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'Completed',
                      completedAppointments.toString(),
                      Colors.green,
                    ),
                    _buildStatItem(
                      'Pending',
                      pendingAppointments.toString(),
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayAppointments(DateTime startOfDay, DateTime endOfDay) {
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
                  'Today\'s Appointments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: widget.doctor.uid)
                  .where('dateTime',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                  .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
                  .orderBy('dateTime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final appointments = snapshot.data!.docs;

                if (appointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No appointments scheduled for today',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointmentData =
                        appointments[index].data() as Map<String, dynamic>;
                    final appointmentTime =
                        (appointmentData['dateTime'] as Timestamp).toDate();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(appointmentData['patientId'])
                          .get(),
                      builder: (context, patientSnapshot) {
                        String patientName = 'Loading...';
                        if (patientSnapshot.hasData) {
                          final patientData = patientSnapshot.data!.data()
                              as Map<String, dynamic>;
                          patientName =
                              patientData['name'] ?? 'Unknown Patient';
                        }

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _getStatusColor(appointmentData['status'])
                                      .withOpacity(0.2),
                              child: Text(
                                patientName.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(
                                      appointmentData['status']),
                                ),
                              ),
                            ),
                            title: Text(patientName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appointmentData['purpose'] ??
                                    'No purpose specified'),
                                Text(
                                  DateFormat('HH:mm a').format(appointmentTime),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) => _handleAppointmentAction(
                                  appointments[index].id, value),
                              itemBuilder: (BuildContext context) => [
                                _buildPopupMenuItem(
                                  'start',
                                  'Start Consultation',
                                  Icons.play_arrow,
                                  Colors.green,
                                ),
                                _buildPopupMenuItem(
                                  'complete',
                                  'Mark Complete',
                                  Icons.check_circle,
                                  Colors.blue,
                                ),
                                _buildPopupMenuItem(
                                  'cancel',
                                  'Cancel',
                                  Icons.cancel,
                                  Colors.red,
                                ),
                                _buildPopupMenuItem(
                                  'noshow',
                                  'Mark No-Show',
                                  Icons.person_off,
                                  Colors.orange,
                                ),
                              ],
                            ),
                            onTap: () =>
                                _showAppointmentDetails(appointments[index]),
                          ),
                        );
                      },
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

  PopupMenuItem<String> _buildPopupMenuItem(
      String value, String text, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _handleAppointmentAction(
      String appointmentId, String action) async {
    try {
      switch (action) {
        case 'start':
          // Navigate to consultation screen
          Navigator.pushNamed(
            context,
            '/consultation',
            arguments: appointmentId,
          );
          break;
        case 'complete':
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointmentId)
              .update({'status': 'completed'});
          break;
        case 'cancel':
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointmentId)
              .update({'status': 'cancelled'});
          break;
        case 'noshow':
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointmentId)
              .update({'status': 'noShow'});
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'noShow':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPendingTasks() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Tasks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildTaskItem(
              'Review Medical Reports',
              '3 reports pending',
              Icons.description,
              Colors.orange,
            ),
            _buildTaskItem(
              'Update Patient Records',
              '5 updates needed',
              Icons.update,
              Colors.blue,
            ),
            _buildTaskItem(
              'Prescription Renewals',
              '2 pending renewals',
              Icons.medical_services,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(
      String title, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          // Handle task action
        },
      ),
    );
  }

  Widget _buildPatientsView() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              // Implement search functionality
              setState(() {
                // Update filtered patients
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('doctorId', isEqualTo: widget.doctor.uid)
                .snapshots(),
            builder: (context, appointmentSnapshot) {
              if (appointmentSnapshot.hasError) {
                return Center(
                    child: Text('Error: ${appointmentSnapshot.error}'));
              }

              if (appointmentSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              // Get unique patient IDs
              final patientIds = appointmentSnapshot.data!.docs
                  .map((doc) => doc['patientId'] as String)
                  .toSet()
                  .toList();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: patientIds)
                    .snapshots(),
                builder: (context, patientSnapshot) {
                  if (patientSnapshot.hasError) {
                    return Center(
                        child: Text('Error: ${patientSnapshot.error}'));
                  }

                  if (patientSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final patients = patientSnapshot.data!.docs
                      .map((doc) => PatientModel.fromMap({
                            ...doc.data() as Map<String, dynamic>,
                            'uid': doc.id,
                          }))
                      .toList();

                  if (patients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No patients found'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: patients.length,
                    padding: EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      return PatientCard(
                        patient: patients[index],
                        onTap: () => _navigateToPatientDetails(patients[index]),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToPatientDetails(PatientModel patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patient: patient),
      ),
    );
  }

  Widget _buildScheduleView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Schedule',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageAvailabilityScreen(
                        doctorId: widget.doctor.uid,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.edit_calendar),
                label: Text('Manage Availability'),
              ),
            ],
          ),
        ),
        DateSelector(
          selectedDate: _selectedDate ?? DateTime.now(),
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
        Expanded(
          child: StreamBuilder<List<AppointmentModel>>(
            stream: _appointmentService.getDoctorDailySchedule(
              widget.doctor.uid,
              _selectedDate ?? DateTime.now(),
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error loading schedule: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final appointments = snapshot.data ?? [];

              return StreamBuilder<List<AvailabilitySlotModel>>(
                stream: _availabilityService
                    .getDoctorAvailability(widget.doctor.uid),
                builder: (context, availabilitySnapshot) {
                  final availableSlots = availabilitySnapshot.data ?? [];

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: 12, // 9 AM to 8 PM
                    itemBuilder: (context, index) {
                      final hour = 9 + index;
                      final timeSlot = DateTime(
                        _selectedDate?.year ?? DateTime.now().year,
                        _selectedDate?.month ?? DateTime.now().month,
                        _selectedDate?.day ?? DateTime.now().day,
                        hour,
                      );

                      final appointment = appointments.firstWhere(
                        (apt) => apt.dateTime.hour == hour,
                        orElse: () => AppointmentModel(
                          id: '',
                          patientId: '',
                          doctorId: widget.doctor.uid,
                          doctorName: widget.doctor.name,
                          purpose: '',
                          dateTime: timeSlot,
                          status: AppointmentStatus.scheduled,
                        ),
                      );

                      bool isAvailable = availableSlots
                          .any((slot) => _isTimeSlotAvailable(slot, timeSlot));

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? Colors.black : Colors.grey,
                            ),
                          ),
                          title: appointment.id.isNotEmpty
                              ? Text(appointment.purpose)
                              : (isAvailable
                                  ? Text('Available',
                                      style: TextStyle(color: Colors.green))
                                  : Text('Unavailable',
                                      style: TextStyle(color: Colors.grey))),
                          subtitle: appointment.id.isNotEmpty
                              ? _buildAppointmentSubtitle(appointment)
                              : null,
                          trailing: appointment.id.isNotEmpty
                              ? _buildAppointmentActions(appointment)
                              : null,
                          onTap: appointment.id.isNotEmpty
                              ? () => _showAppointmentDetails(
                                  appointment as DocumentSnapshot<Object?>)
                              : null,
                          tileColor: appointment.id.isNotEmpty
                              ? _getAppointmentColor(appointment.status)
                              : null,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentSubtitle(AppointmentModel appointment) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(appointment.patientId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Text('Loading patient info...');

        final patientData = snapshot.data!.data() as Map<String, dynamic>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${patientData['name'] ?? 'Unknown'}'),
            Text('Purpose: ${appointment.purpose}'),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentActions(AppointmentModel appointment) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'complete':
            await _appointmentService.updateAppointmentStatus(
              appointment.id,
              AppointmentStatus.completed,
            );
            break;
          case 'cancel':
            await _appointmentService.updateAppointmentStatus(
              appointment.id,
              AppointmentStatus.cancelled,
            );
            break;
          case 'noshow':
            await _appointmentService.updateAppointmentStatus(
              appointment.id,
              AppointmentStatus.noShow,
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'complete',
          child: ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Mark Complete'),
          ),
        ),
        PopupMenuItem(
          value: 'cancel',
          child: ListTile(
            leading: Icon(Icons.cancel, color: Colors.red),
            title: Text('Cancel'),
          ),
        ),
        PopupMenuItem(
          value: 'noshow',
          child: ListTile(
            leading: Icon(Icons.person_off, color: Colors.orange),
            title: Text('Mark No-Show'),
          ),
        ),
      ],
    );
  }

  Color _getAppointmentColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue.withOpacity(0.1);
      case AppointmentStatus.completed:
        return Colors.green.withOpacity(0.1);
      case AppointmentStatus.cancelled:
        return Colors.red.withOpacity(0.1);
      case AppointmentStatus.noShow:
        return Colors.orange.withOpacity(0.1);
    }
  }

  bool _isTimeSlotAvailable(AvailabilitySlotModel slot, DateTime timeSlot) {
    if (!slot.isAvailable) return false;

    if (slot.isRecurring) {
      String weekday = DateFormat('EEEE').format(timeSlot);
      if (!slot.recurringDays.contains(weekday)) return false;
    }

    final slotStartTime = TimeOfDay.fromDateTime(slot.startTime);
    final slotEndTime = TimeOfDay.fromDateTime(slot.endTime);
    final checkTime = TimeOfDay.fromDateTime(timeSlot);

    return _isTimeBetween(slotStartTime, slotEndTime, checkTime);
  }

  bool _isTimeBetween(TimeOfDay start, TimeOfDay end, TimeOfDay check) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final checkMinutes = check.hour * 60 + check.minute;

    return checkMinutes >= startMinutes && checkMinutes <= endMinutes;
  }

  Widget _buildAppointmentStatus(AppointmentStatus status) {
    Color color;
    String text;

    switch (status) {
      case AppointmentStatus.scheduled:
        color = Colors.blue;
        text = 'Scheduled';
        break;
      case AppointmentStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case AppointmentStatus.noShow:
        color = Colors.orange;
        text = 'No Show';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildWeekCalendar() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 4),
            color: index == 0 ? Colors.blue : null,
            child: Container(
              width: 60,
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: index == 0 ? Colors.white : null,
                    ),
                  ),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: index == 0 ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionSheet() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Add Appointment'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/add-appointment');
            },
          ),
          ListTile(
            leading: Icon(Icons.person_add),
            title: Text('Add New Patient'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/add-patient');
            },
          ),
          ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Update Schedule'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/update-schedule');
            },
          ),
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Manage Availability'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageAvailabilityScreen(
                    doctorId: widget.doctor.uid,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(DocumentSnapshot appointment) {
    // Show appointment details modal
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final appointmentData = appointment.data() as Map<String, dynamic>;
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appointment Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(appointmentData['patientId'])
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }

                  final patientData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                          'Patient', patientData['name'] ?? 'Unknown'),
                      _buildDetailRow(
                          'Purpose', appointmentData['purpose'] ?? 'N/A'),
                      _buildDetailRow(
                        'Time',
                        DateFormat('HH:mm a').format(
                          (appointmentData['dateTime'] as Timestamp).toDate(),
                        ),
                      ),
                      _buildDetailRow('Status', appointmentData['status']),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPatientOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.medical_services),
              title: Text('Add Prescription'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to prescription page
              },
            ),
            ListTile(
              leading: Icon(Icons.note_add),
              title: Text('Add Medical Note'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to medical note page
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('View History'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to patient history
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
