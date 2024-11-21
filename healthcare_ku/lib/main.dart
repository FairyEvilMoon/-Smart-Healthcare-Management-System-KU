import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare_ku/models/user_model.dart';
import 'package:healthcare_ku/models/admin_model.dart'; // Add this import
import 'package:healthcare_ku/models/doctor_model.dart'; // Add this import
import 'package:healthcare_ku/models/patient_model.dart'; // Add this import
import 'firebase_options.dart';
import 'middleware/doctor_verification_middleware.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard/patient/patient_dashboard.dart';
import 'screens/dashboard/doctor_dashboard.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthcare App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          if (snapshot.hasData) {
            return FutureBuilder(
              future: _firebaseService.getUserData(snapshot.data!.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }

                if (userSnapshot.hasData) {
                  final userData = userSnapshot.data!;
                  return _buildUserDashboard(userData);
                }

                return LoginScreen();
              },
            );
          }

          return LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/patient-dashboard': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return LoginScreen();

          return FutureBuilder<UserModel?>(
            future: _firebaseService.getUserData(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              if (snapshot.hasData && snapshot.data?.role == 'patient') {
                final patientData = PatientModel(
                  uid: snapshot.data!.uid,
                  email: snapshot.data!.email,
                  name: snapshot.data!.name,
                  phoneNumber: snapshot.data!.phoneNumber,
                  profileImageUrl: snapshot.data!.profileImageUrl,
                );
                return PatientDashboard(patient: patientData);
              }

              return LoginScreen();
            },
          );
        },
        '/doctor-dashboard': (context) => _wrapDoctorDashboard(context),
        '/admin-dashboard': (context) => _wrapAdminDashboard(context),
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildUserDashboard(UserModel userData) {
    switch (userData.role) {
      case 'patient':
        final patientData = PatientModel(
          uid: userData.uid,
          email: userData.email,
          name: userData.name,
          phoneNumber: userData.phoneNumber,
          profileImageUrl: userData.profileImageUrl,
        );
        return PatientDashboard(patient: patientData);
      case 'doctor':
        final doctorData = DoctorModel(
          uid: userData.uid,
          email: userData.email,
          name: userData.name,
          phoneNumber: userData.phoneNumber,
          profileImageUrl: userData.profileImageUrl,
        );
        return DoctorVerificationMiddleware(
          uid: userData.uid,
          child: DoctorDashboard(doctor: doctorData),
        );
      case 'admin':
        final adminData = AdminModel(
          uid: userData.uid,
          email: userData.email,
          name: userData.name,
          phoneNumber: userData.phoneNumber,
          profileImageUrl: userData.profileImageUrl,
        );
        return AdminDashboard(admin: adminData);
      default:
        return LoginScreen();
    }
  }

  Widget _wrapDoctorDashboard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return LoginScreen();

    return FutureBuilder<UserModel?>(
      future: _firebaseService.getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasData && snapshot.data?.role == 'doctor') {
          final doctorData = DoctorModel(
            uid: snapshot.data!.uid,
            email: snapshot.data!.email,
            name: snapshot.data!.name,
            phoneNumber: snapshot.data!.phoneNumber,
            profileImageUrl: snapshot.data!.profileImageUrl,
          );
          return DoctorVerificationMiddleware(
            uid: user.uid,
            child: DoctorDashboard(doctor: doctorData),
          );
        }

        return LoginScreen();
      },
    );
  }

  Widget _wrapAdminDashboard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return LoginScreen();

    return FutureBuilder<UserModel?>(
      future: _firebaseService.getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasData && snapshot.data?.role == 'admin') {
          final adminData = AdminModel(
            uid: snapshot.data!.uid,
            email: snapshot.data!.email,
            name: snapshot.data!.name,
            phoneNumber: snapshot.data!.phoneNumber,
            profileImageUrl: snapshot.data!.profileImageUrl,
          );
          return AdminDashboard(admin: adminData);
        }

        return LoginScreen();
      },
    );
  }
}
