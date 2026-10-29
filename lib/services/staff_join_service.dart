import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffJoinService {
  StaffJoinService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> submitJoinRequest({
    required String businessId,
    required String email,
    required String password,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final normalizedEmail = email.trim();

    if (normalizedBusinessId.isEmpty ||
        normalizedBusinessId.length > 128) {
      throw ArgumentError(
        'Enter a valid business ID provided by the owner.',
      );
    }

    if (normalizedEmail.isEmpty) {
      throw ArgumentError('Enter your email address.');
    }

    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters.');
    }

    if (_auth.currentUser != null) {
      throw StateError(
        'Please sign out before submitting a staff join request.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null || user.email == null) {
      await _auth.signOut();
      throw StateError(
        'Your account was created, but its email could not be verified.',
      );
    }

    try {
      await _firestore.collection('joinRequests').doc(user.uid).set({
        'businessId': normalizedBusinessId,
        'email': user.email,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }

    await _auth.signOut();
  }
}
