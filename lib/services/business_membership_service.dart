import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessMembershipService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  BusinessMembershipService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns the signed-in user's verified business membership.
  ///
  /// Owners are verified against their existing user profile.
  /// Staff must also have an active membership record in their business.
  Future<Map<String, dynamic>> getCurrentMembership() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in to access your business.');
    }

    final profileSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!profileSnapshot.exists) {
      throw StateError(
        'Your Veroon account has not been approved yet. '
        'Please wait for the business owner to review your request.',
      );
    }

    final profile = profileSnapshot.data();

    if (profile == null) {
      throw StateError('Your business profile could not be loaded.');
    }

    final role = profile['role'];
    final businessId = profile['businessId'];
    final profileStatus = profile['status'];

    if (role != 'owner' && role != 'staff') {
      throw StateError('Your account does not have an approved role.');
    }

    if (businessId is! String || businessId.trim().isEmpty) {
      throw StateError('Your account has not been assigned to a business.');
    }

    // Preserve support for older owner profiles without a status field.
    if (profileStatus != null && profileStatus != 'active') {
      throw StateError('Your Veroon account is not active.');
    }

    if (role == 'owner') {
      return {
        'userId': user.uid,
        'email': user.email,
        'businessId': businessId,
        'role': 'owner',
        'status': 'active',
      };
    }

    // Staff must have a membership document for the same business.
    final memberSnapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('members')
        .doc(user.uid)
        .get();

    if (!memberSnapshot.exists) {
      throw StateError(
        'You do not have an approved membership in this business.',
      );
    }

    final member = memberSnapshot.data();

    if (member == null || member['role'] != 'staff') {
      throw StateError('Your business membership is invalid.');
    }

    if (member['status'] != 'active') {
      throw StateError(
        'Your staff access is disabled. Please contact the business owner.',
      );
    }

    final memberEmail = member['email'];
    if (memberEmail is! String ||
        user.email == null ||
        memberEmail.toLowerCase() != user.email!.toLowerCase()) {
      throw StateError(
        'Your account email does not match the business membership.',
      );
    }

    return {
      'userId': user.uid,
      'email': user.email,
      'businessId': businessId,
      'role': 'staff',
      'status': 'active',
    };
  }

  /// Checks whether the signed-in user is an owner.
  Future<bool> isCurrentUserOwner() async {
    final membership = await getCurrentMembership();
    return membership['role'] == 'owner';
  }

  /// Returns the current user's verified business ID.
  Future<String> getCurrentBusinessId() async {
    final membership = await getCurrentMembership();
    return membership['businessId'] as String;
  }
}
