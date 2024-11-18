import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class DoctorVerificationMiddleware extends StatefulWidget {
  final Widget child;
  final String uid;

  DoctorVerificationMiddleware({
    required this.child,
    required this.uid,
  });

  @override
  _DoctorVerificationMiddlewareState createState() =>
      _DoctorVerificationMiddlewareState();
}

class _DoctorVerificationMiddlewareState
    extends State<DoctorVerificationMiddleware> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _firebaseService.isDoctorVerified(widget.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return widget.child;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Account Pending'),
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pending_actions,
                    size: 64,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Account Verification Pending',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your account is currently under review. You will be notified once your account has been verified by an administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
