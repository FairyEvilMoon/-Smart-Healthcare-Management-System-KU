final authStateProvider = StreamProvider((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
});
