import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'staff_join_screen.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _creatingAccount = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _businessName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final auth = FirebaseAuth.instance;
    final email = _email.text.trim();

    try {
      if (_creatingAccount) {
        final businessName = _businessName.text.trim();

        final credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: _password.text,
        );

        final user = credential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'account-creation-failed',
            message: 'Your account could not be created. Please try again.',
          );
        }

        try {
          await FirebaseFirestore.instance
              .collection('accessRequests')
              .doc(user.uid)
              .set({
                'businessName': businessName,
                'email': user.email,
                'status': 'pending',
                'createdAt': FieldValue.serverTimestamp(),
              });
        } catch (_) {
          // Keep the new account. Do not ask the user to register again.
          if (!mounted) return;

          setState(() {
            _success =
                'Your login account was created, but your access request '
                'could not be submitted. Please sign in again later or '
                'contact the administrator for assistance.';
          });

          await auth.signOut();
          return;
        }

        if (!mounted) return;

        setState(() {
          _success =
              'Your registration request has been submitted. '
              'Please wait for an administrator to approve your access.';
        });

        // AuthGate will show the pending-access screen until an
        // administrator creates the approved user profile.
        await auth.signOut();
      } else {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = switch (e.code) {
          'invalid-email' => 'Please enter a valid email address.',
          'user-not-found' ||
          'wrong-password' ||
          'invalid-credential' => 'Email or password is incorrect.',
          'email-already-in-use' =>
            'An account already exists for this email. Please sign in.',
          'weak-password' =>
            'Choose a stronger password (at least 6 characters).',
          'too-many-requests' =>
            'Too many attempts. Please wait and try again.',
          'network-request-failed' =>
            'Network error. Check your internet connection.',
          'operation-not-allowed' =>
            'Email/Password sign-in is not enabled in Firebase.',
          'account-creation-failed' =>
            'Your account could not be created. Please try again.',
          _ => e.message ?? 'Authentication failed. Please try again.',
        };
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _email.text.trim();

    if (email.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      setState(() {
        _error = 'Enter a valid email address first.';
        _success = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        _success =
            'If an account exists for this email, a password reset email has been sent.';
      });
    } on FirebaseAuthException {
      if (!mounted) return;
      setState(() {
        _error = 'Could not send the reset email. Please try again later.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipOval(
                        child: Image.asset(
                          'assets/veroon profile.jpeg',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Veroon',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _creatingAccount
                          ? 'Register your business'
                          : 'Sign in to your business dashboard',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_creatingAccount) ...[
                      TextFormField(
                        controller: _businessName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Business name',
                          prefixIcon: Icon(Icons.store_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (!_creatingAccount) return null;
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) {
                            return 'Enter your business name.';
                          }
                          if (name.length > 100) {
                            return 'Business name must be 100 characters or fewer.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                .hasMatch(value.trim())) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      autofillHints: [
                        _creatingAccount
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    if (!_creatingAccount) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              _loading ? null : _sendPasswordResetEmail,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_success != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _success!,
                        style: TextStyle(color: theme.colorScheme.primary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _creatingAccount
                                    ? 'Submit registration'
                                    : 'Sign in',
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                _creatingAccount = !_creatingAccount;
                                _error = null;
                                _success = null;
                              });
                            },
                      child: Text(
                        _creatingAccount
                            ? 'Already have an account? Sign in'
                            : 'First time here? Register your business',
                      ),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const StaffJoinScreen(),
                                ),
                              );
                            },
                      child: const Text("Staff? Join your business"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
