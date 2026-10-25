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

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();

    if (!snapshot.exists ||
        data == null ||
        data['role'] != 'owner' ||
        (data['status'] != null && data['status'] != 'active')) {
      throw StateError('Only an active business owner can manage staff.');
    }

    final businessId = data['businessId'];

    if (businessId is! String || businessId.trim().isEmpty) {
      throw StateError('Your owner account has no business assigned.');
    }

    return businessId;
  }

  Future<void> approveRequest(String staffUid) async {
    final owner = _auth.currentUser;
    final businessId = await _requireOwnerBusinessId();

    if (owner == null || staffUid == owner.uid) {
      throw StateError('You cannot approve your own staff request.');
    }

    final requestRef = _firestore.collection('joinRequests').doc(staffUid);
    final memberRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('members')
        .doc(staffUid);
    final profileRef = _firestore.collection('users').doc(staffUid);

    await _firestore.runTransaction((transaction) async {
      // Read all documents before making any transaction writes.
      final requestSnapshot = await transaction.get(requestRef);
      final memberSnapshot = await transaction.get(memberRef);
      final profileSnapshot = await transaction.get(profileRef);

      if (!requestSnapshot.exists) {
        throw StateError('This join request no longer exists.');
      }

      final request = requestSnapshot.data()!;

      if (request['businessId'] != businessId ||
          request['status'] != 'pending') {
        throw StateError('This request is not pending for your business.');
      }

      if (memberSnapshot.exists || profileSnapshot.exists) {
        throw StateError(
          'A membership or user profile already exists. '
          'Please investigate before approving this request.',
        );
      }

      final email = request['email'];

      if (email is! String || email.trim().isEmpty || email != email.trim()) {
        throw StateError('The join request has an invalid email address.');
      }

      transaction.update(requestRef, {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': owner.uid,
      });

      transaction.set(memberRef, {
        'role': 'staff',
        'status': 'active',
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(profileRef, {
        'businessId': businessId,
        'role': 'staff',
        'status': 'active',
        'email': email,
      });
    });
  }

  Future<void> rejectRequest(String staffUid) async {
    final owner = _auth.currentUser;
    final businessId = await _requireOwnerBusinessId();

    if (owner == null || staffUid == owner.uid) {
      throw StateError('You cannot reject your own staff request.');
    }

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
        'reviewedBy': owner.uid,
      });
    });
  }

  Future<void> setStaffStatus({
    required String staffUid,
    required String status,
  }) async {
    if (status != 'active' && status != 'disabled') {
      throw ArgumentError.value(
        status,
        'status',
        'Status must be active or disabled.',
      );
    }

    final owner = _auth.currentUser;
    final businessId = await _requireOwnerBusinessId();

    if (owner == null || staffUid == owner.uid) {
      throw StateError('You cannot change your own staff status.');
    }

    final memberRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('members')
        .doc(staffUid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(memberRef);

      if (!snapshot.exists) {
        throw StateError('This staff membership no longer exists.');
      }

      final member = snapshot.data()!;

      if (member['role'] != 'staff') {
        throw StateError('Only staff memberships can be changed.');
      }

      if (member['status'] != 'active' && member['status'] != 'disabled') {
        throw StateError('This staff membership has an invalid status.');
      }

      transaction.update(memberRef, {'status': status});
    });
  }
}
