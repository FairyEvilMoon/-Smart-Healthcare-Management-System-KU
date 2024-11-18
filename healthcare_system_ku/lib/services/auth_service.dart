class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        return doc.exists ? UserModel.fromMap(doc.data()!) : null;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phoneNumber,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          role: role,
          phoneNumber: phoneNumber,
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());

        return userModel;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
