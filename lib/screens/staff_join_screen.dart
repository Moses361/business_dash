import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/staff_join_service.dart';

class StaffJoinScreen extends StatefulWidget {
  const StaffJoinScreen({super.key});

  @override
  State<StaffJoinScreen> createState() => _StaffJoinScreenState();
}

class _StaffJoinScreenState extends State<StaffJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessId = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _businessId.dispose();
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

    try {
      await StaffJoinService().submitJoinRequest(
        businessId: _businessId.text,
        email: _email.text,
        password: _password.text,
      );

      if (!mounted) return;

      setState(() {
        _success =
            'Your request has been submitted. The business owner must '
            'approve it before you can access the dashboard.';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = switch (e.code) {
          'email-already-in-use' =>
            'An account already exists for this email. Please sign in.',
          'invalid-email' => 'Enter a valid email address.',
          'weak-password' => 'Choose a stronger password.',
          'operation-not-allowed' =>
            'Email and password registration is not enabled.',
          'network-request-failed' =>
            'Network error. Check your internet connection.',
          _ => e.message ?? 'Could not create your account. Please try again.',
        };
      });
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message?.toString() ?? 'Check your details.');
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not submit your request. If your account was created, '
            'contact the business owner before trying again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Join a business')),
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
                    const Icon(Icons.groups_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Join your team',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the business ID provided by the owner. '
                      'Your request must be approved before you can sign in '
                      'to the staff dashboard.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _businessId,
                      textCapitalization: TextCapitalization.none,
                      decoration: const InputDecoration(
                        labelText: 'Business ID',
                        prefixIcon: Icon(Icons.store_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final id = value?.trim() ?? '';
                        if (id.isEmpty) return 'Enter the business ID.';
                        if (id.length > 128) return 'Business ID is too long.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Create password',
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
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    if (_success != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _success!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading || _success != null ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit join request'),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Back to sign in'),
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
