import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/owner_login_screen.dart';

class AuthGate extends StatelessWidget {
  final Widget signedInHome;

  const AuthGate({super.key, required this.signedInHome});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingView();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const OwnerLoginScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingView();
            }

            if (profileSnapshot.hasError) {
              return _AccessMessage(
                title: 'Unable to verify access',
                message:
                    'Check your internet connection and Firestore access '
                    'permissions, then try again.',
                onSignOut: _signOut,
              );
            }

            final profileSnapshotData = profileSnapshot.data;
            final profileExists =
                profileSnapshotData != null && profileSnapshotData.exists;

            if (!profileExists) {
              return _buildJoinRequestGate(user);
            }

            final profile = profileSnapshotData.data();

            if (profile == null) {
              return _AccessMessage(
                title: 'Profile unavailable',
                message:
                    'Your Veroon profile could not be loaded. '
                    'Please contact the business owner.',
                onSignOut: _signOut,
              );
            }

            final role = profile['role'];
            final businessId = profile['businessId'];
            final status = profile['status'];

            if (role != 'owner' && role != 'staff') {
              return _AccessMessage(
                title: 'Access not authorized',
                message: 'Your account does not have an approved Veroon role.',
                onSignOut: _signOut,
              );
            }

            if (businessId is! String || businessId.trim().isEmpty) {
              return _AccessMessage(
                title: 'Business not assigned',
                message:
                    'Your account has not been assigned to a Veroon business.',
                onSignOut: _signOut,
              );
            }

            if (status != null && status != 'active') {
              return _AccessMessage(
                title: 'Account not active',
                message:
                    'Your Veroon account is not active. '
                    'Please contact the business owner.',
                onSignOut: _signOut,
              );
            }

            // Preserve the existing owner login behavior.
            if (role == 'owner') {
              return signedInHome;
            }

            // Staff must have a matching active membership record.
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('businesses')
                  .doc(businessId)
                  .collection('members')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, memberSnapshot) {
                if (memberSnapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingView();
                }

                if (memberSnapshot.hasError) {
                  return _AccessMessage(
                    title: 'Unable to verify membership',
                    message:
                        'Veroon could not verify your staff membership. '
                        'Check your connection and Firestore permissions.',
                    onSignOut: _signOut,
                  );
                }

                final memberDocument = memberSnapshot.data;

                if (memberDocument == null || !memberDocument.exists) {
                  return _AccessMessage(
                    title: 'Membership not found',
                    message:
                        'Your account does not have a staff membership '
                        'for this business. Please contact the owner.',
                    onSignOut: _signOut,
                  );
                }

                final member = memberDocument.data();

                if (member == null || member['role'] != 'staff') {
                  return _AccessMessage(
                    title: 'Invalid membership',
                    message:
                        'Your staff membership could not be verified. '
                        'Please contact the business owner.',
                    onSignOut: _signOut,
                  );
                }

                if (member['status'] != 'active') {
                  return _AccessMessage(
                    title: 'Staff access disabled',
                    message:
                        'Your access to this business is disabled. '
                        'Please contact the business owner.',
                    onSignOut: _signOut,
                  );
                }

                final memberEmail = member['email'];
                final userEmail = user.email;

                if (memberEmail is! String ||
                    userEmail == null ||
                    memberEmail.toLowerCase() != userEmail.toLowerCase()) {
                  return _AccessMessage(
                    title: 'Membership email mismatch',
                    message:
                        'Your signed-in email does not match the email '
                        'registered for this staff membership.',
                    onSignOut: _signOut,
                  );
                }

                return signedInHome;
              },
            );
          },
        );
      },
    );
  }

  Widget _buildJoinRequestGate(User user) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('joinRequests')
          .doc(user.uid)
          .snapshots(),
      builder: (context, requestSnapshot) {
        if (requestSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingView();
        }

        if (requestSnapshot.hasError) {
          return _AccessMessage(
            title: 'Unable to verify your request',
            message:
                'Your staff request could not be checked. '
                'Please check your connection and try again.',
            onSignOut: _signOut,
          );
        }

        final requestDocument = requestSnapshot.data;

        if (requestDocument == null || !requestDocument.exists) {
          return _AccessMessage(
            title: 'Access pending',
            message:
                'Your account does not have an approved Veroon profile '
                'or a staff join request. Contact your business owner.',
            onSignOut: _signOut,
          );
        }

        final request = requestDocument.data();

        if (request == null) {
          return _AccessMessage(
            title: 'Request unavailable',
            message:
                'Your staff request could not be loaded. '
                'Please contact the business owner.',
            onSignOut: _signOut,
          );
        }

        switch (request['status']) {
          case 'pending':
            return _AccessMessage(
              title: 'Waiting for approval',
              message:
                  'Your staff join request has been submitted. '
                  'You can enter the dashboard after the owner approves '
                  'your membership.',
              onSignOut: _signOut,
            );

          case 'rejected':
            return _AccessMessage(
              title: 'Request not approved',
              message:
                  'Your request to join this business was rejected. '
                  'Please contact the business owner.',
              onSignOut: _signOut,
            );

          case 'approved':
            return _AccessMessage(
              title: 'Membership verification required',
              message:
                  'Your request was approved, but an approved staff '
                  'profile and active membership are still required. '
                  'Please contact the business owner.',
              onSignOut: _signOut,
            );

          default:
            return _AccessMessage(
              title: 'Access not authorized',
              message:
                  'Your staff request has an invalid status. '
                  'Please contact the business owner.',
              onSignOut: _signOut,
            );
        }
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AccessMessage extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onSignOut;

  const _AccessMessage({
    required this.title,
    required this.message,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/veroon logo.png",
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const SelectableText(
                "Owner contact: 0727655605",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: onSignOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
