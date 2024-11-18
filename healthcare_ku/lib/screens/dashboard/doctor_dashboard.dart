import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/doctor_model.dart';
import '../../services/firebase_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
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
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh today's data
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoctorStats(),
            SizedBox(height: 16),
            _buildTodayAppointments(),
            SizedBox(height: 16),
            _buildPendingTasks(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorStats() {
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
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(widget.doctor.specialization ?? 'Specialization'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Today\'s\nAppointments', '8'),
                _buildStatItem('Pending\nReviews', '3'),
                _buildStatItem('Total\nPatients', '145'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
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

  Widget _buildTodayAppointments() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Appointments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 1,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text('John Doe'),
                    subtitle: Text('General Checkup'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('10:00 AM'),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Confirmed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showAppointmentDetails(index),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text('Patient Name ${index + 1}'),
                    subtitle: Text(
                        'Last Visit: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
                    trailing: IconButton(
                      icon: Icon(Icons.medical_services),
                      onPressed: () => _showPatientOptions(index),
                    ),
                    onTap: () => _navigateToPatientDetails(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleView() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildWeekCalendar(),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                final hour = 9 + index;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    title: index % 3 == 0 ? Text('Patient Appointment') : null,
                    subtitle: index % 3 == 0 ? Text('General Checkup') : null,
                    tileColor:
                        index % 3 == 0 ? Colors.blue.withOpacity(0.1) : null,
                  ),
                );
              },
            ),
          ),
        ],
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
        ],
      ),
    );
  }

  void _showAppointmentDetails(int index) {
    // Show appointment details dialog or navigate to details page
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

  void _navigateToPatientDetails(int index) {
    // Navigate to patient details page
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
