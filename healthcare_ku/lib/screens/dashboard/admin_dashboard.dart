import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthcare_ku/models/user_model.dart';
import '../../models/admin_model.dart';
import '../../services/firebase_service.dart';

class AdminDashboard extends StatefulWidget {
  final AdminModel admin;

  AdminDashboard({required this.admin});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              // Handle profile
            },
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(widget.admin.name),
            accountEmail: Text(widget.admin.email),
            currentAccountPicture: CircleAvatar(
              backgroundImage: widget.admin.profileImageUrl != null
                  ? NetworkImage(widget.admin.profileImageUrl!)
                  : null,
              child: widget.admin.profileImageUrl == null
                  ? Icon(Icons.person)
                  : null,
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            leading: Icon(Icons.verified_user),
            title: Text('Doctor Verification'),
            onTap: () {
              Navigator.pop(context);
              _showDoctorVerificationPanel();
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('User Management'),
            onTap: () {
              Navigator.pop(context);
              _showUserManagementPanel();
            },
          ),
          ListTile(
            leading: Icon(Icons.analytics),
            title: Text('System Analytics'),
            onTap: () {
              Navigator.pop(context);
              _showAnalyticsPanel();
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('System Settings'),
            onTap: () {
              Navigator.pop(context);
              _showSettingsPanel();
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewPanel();
      case 1:
        return _buildUsersPanel();
      case 2:
        return _buildAnalyticsPanel();
      default:
        return _buildOverviewPanel();
    }
  }

  Widget _buildOverviewPanel() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsCards(),
          SizedBox(height: 24),
          _buildPendingVerifications(),
          SizedBox(height: 24),
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Users',
          '1,234',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Doctors',
          '56',
          Icons.medical_services,
          Colors.green,
        ),
        _buildStatCard(
          'Pending Verifications',
          '8',
          Icons.verified_user,
          Colors.orange,
        ),
        _buildStatCard(
          'Today\'s Appointments',
          '89',
          Icons.calendar_today,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingVerifications() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Doctor Verifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text('Dr. John Doe'),
                    subtitle: Text('Cardiologist • Applied 2 days ago'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            // Approve doctor
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            // Reject doctor
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(Icons.update, color: Colors.blue),
                  ),
                  title: Text('New doctor registration'),
                  subtitle: Text('2 minutes ago'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersPanel() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  tabs: [
                    Tab(text: 'Doctors'),
                    Tab(text: 'Patients'),
                    Tab(text: 'Admins'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildUserList('doctor'),
                      _buildUserList('patient'),
                      _buildUserList('admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserList(String userType) {
    return FutureBuilder<List<UserModel>>(
      future: _firebaseService.getUsersByRole(userType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('No ${userType}s found'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8.0),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child:
                      user.profileImageUrl == null ? Icon(Icons.person) : null,
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: PopupMenuButton(
                  onSelected: (value) => _handleUserAction(value, user),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('View Details'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'suspend',
                      child: ListTile(
                        leading: Icon(Icons.block),
                        title: Text('Suspend'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showUserDetails(user),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserOptions(int index, String userType) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit User'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle edit user
                },
              ),
              ListTile(
                leading: Icon(Icons.block),
                title: Text('Suspend User'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle suspend user
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete User'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle delete user
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsPanel() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsCards(),
          SizedBox(height: 24),
          _buildUserGrowthChart(),
          SizedBox(height: 24),
          _buildAppointmentStats(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildAnalyticCard(
          'User Growth',
          '+12%',
          'Last 30 days',
          Icons.trending_up,
          Colors.green,
        ),
        _buildAnalyticCard(
          'Appointment Rate',
          '85%',
          'Completion rate',
          Icons.check_circle,
          Colors.blue,
        ),
        _buildAnalyticCard(
          'Active Users',
          '892',
          'Last 7 days',
          Icons.people,
          Colors.purple,
        ),
        _buildAnalyticCard(
          'System Health',
          '99.9%',
          'Uptime',
          Icons.health_and_safety,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildAnalyticCard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Growth',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: Center(
                child: Text('User Growth Chart will be displayed here'),
                // Implement chart using a charting library like fl_chart or charts_flutter
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentStats() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(Icons.calendar_today, color: Colors.blue),
              ),
              title: Text('Total Appointments'),
              trailing: Text('1,234'),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
              title: Text('Completed'),
              trailing: Text('1,048'),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withOpacity(0.1),
                child: Icon(Icons.pending, color: Colors.orange),
              ),
              title: Text('Pending'),
              trailing: Text('186'),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                child: Icon(Icons.cancel, color: Colors.red),
              ),
              title: Text('Cancelled'),
              trailing: Text('42'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUserAction(String action, UserModel user) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'suspend':
        _showSuspendUserDialog(user);
        break;
      case 'delete':
        _showDeleteUserDialog(user);
        break;
    }
  }

  void _showUserDetails(UserModel user) {
    // Implement user details dialog or navigate to user details screen
  }

  void _showEditUserDialog(UserModel user) {
    // Implement edit user dialog
  }

  void _showSuspendUserDialog(UserModel user) {
    // Implement suspend user dialog
  }

  void _showDeleteUserDialog(UserModel user) {
    // Implement delete user dialog
  }

  // Add these methods to handle various panel displays
  void _showDoctorVerificationPanel() {
    // Implement doctor verification panel
  }

  void _showUserManagementPanel() {
    // Implement user management panel
  }

  void _showAnalyticsPanel() {
    // Implement analytics panel
  }

  void _showSettingsPanel() {
    // Implement settings panel
  }
}
