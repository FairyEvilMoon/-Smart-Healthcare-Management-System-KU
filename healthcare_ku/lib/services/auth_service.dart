import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  // Check if user is doctor
  Future<bool> isDoctor(String uid) async {
    try {
      String? role = await getUserRole(uid);
      return role == 'doctor';
    } catch (e) {
      throw Exception('Failed to check doctor status: $e');
    }
  }

  // Get current user role
  Future<String?> getCurrentUserRole() async {
    if (currentUser != null) {
      return await getUserRole(currentUser!.uid);
    }
    return null;
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(currentUser!.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      } catch (e) {
        throw Exception('Failed to get user data: $e');
      }
    }
    return null;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(displayName);
        await currentUser!.updatePhotoURL(photoURL);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
