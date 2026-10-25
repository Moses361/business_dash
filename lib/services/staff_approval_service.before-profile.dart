import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffApprovalService {
  StaffApprovalService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<String> _requireOwnerBusinessId() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in as the business owner.');
    }

    final profile = await _firestore.collection('users').doc(user.uid).get();

    final data = profile.data();

    if (!profile.exists ||
        data == null ||
        data['role'] != 'owner' ||
        data['status'] != null && data['status'] != 'active') {
      throw StateError('Only an active business owner can manage staff.');
    }

    final businessId = data['businessId'];

    if (businessId is! String || businessId.trim().isEmpty) {
      throw StateError('Your owner account has no business assigned.');
    }

    return businessId;
  }

  Future<void> approveRequest(String staffUid) async {
    final businessId = await _requireOwnerBusinessId();

    final requestRef = _firestore.collection('joinRequests').doc(staffUid);
    final memberRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('members')
        .doc(staffUid);

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      final memberSnapshot = await transaction.get(memberRef);

      if (!requestSnapshot.exists) {
        throw StateError('This join request no longer exists.');
      }

      final request = requestSnapshot.data()!;
      if (request['businessId'] != businessId ||
          request['status'] != 'pending') {
        throw StateError('This request is not pending for your business.');
      }

      if (memberSnapshot.exists) {
        throw StateError('A membership record already exists.');
      }

      final email = request['email'];
      if (email is! String || email.isEmpty) {
        throw StateError('The join request has no valid email address.');
      }

      transaction.update(requestRef, {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _auth.currentUser!.uid,
      });

      transaction.set(memberRef, {
        'role': 'staff',
        'status': 'active',
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectRequest(String staffUid) async {
    final businessId = await _requireOwnerBusinessId();
    final requestRef = _firestore.collection('joinRequests').doc(staffUid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(requestRef);

      if (!snapshot.exists) {
        throw StateError('This join request no longer exists.');
      }

      final request = snapshot.data()!;

      if (request['businessId'] != businessId ||
          request['status'] != 'pending') {
        throw StateError('This request is not pending for your business.');
      }

      transaction.update(requestRef, {
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _auth.currentUser!.uid,
      });
    });
  }
}
