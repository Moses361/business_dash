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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        // Show the actual login form when signed out.
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
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return _AccessMessage(
                title: 'Unable to verify access',
                message:
                    'Check your internet connection and access permissions.',
                onSignOut: _signOut,
              );
            }

            final profile = profileSnapshot.data;

            if (profile == null || !profile.exists) {
              return _AccessMessage(
                title: 'Access pending',
                message: 'Your account exists, but an administrator must approve your Veroon access.',
                onSignOut: _signOut,
              );
            }

            final role = profile.data()?['role'];

            if (role != 'owner' && role != 'staff') {
              return _AccessMessage(
                title: 'Access not authorized',
                message: 'Your account does not have an approved Veroon role.',
                onSignOut: _signOut,
              );
            }

            return signedInHome;
          },
        );
      },
    );
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
                  const Icon(Icons.storefront, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => onSignOut(),
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
