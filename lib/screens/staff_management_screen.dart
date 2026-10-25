import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/business_membership_service.dart';
import '../services/staff_approval_service.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  static const Color _background = Color(0xFFF6F8F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Staff Management',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202824),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: BusinessMembershipService().getCurrentMembership(),
        builder: (context, membershipSnapshot) {
          if (membershipSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (membershipSnapshot.hasError || !membershipSnapshot.hasData) {
            return _MessageView(
              icon: Icons.lock_outline_rounded,
              title: 'Unable to load team',
              message:
                  membershipSnapshot.error?.toString() ??
                  'Your business membership could not be loaded.',
            );
          }

          final membership = membershipSnapshot.data!;

          if (membership['role'] != 'owner') {
            return const _MessageView(
              icon: Icons.shield_outlined,
              title: 'Owner access required',
              message: 'Only the business owner can manage staff members.',
            );
          }

          final businessId = membership['businessId'];

          if (businessId is! String || businessId.trim().isEmpty) {
            return const _MessageView(
              icon: Icons.business_outlined,
              title: 'Business not configured',
              message: 'Your owner account has no business assigned.',
            );
          }

          return _StaffDirectory(businessId: businessId);
        },
      ),
    );
  }
}

class _StaffDirectory extends StatelessWidget {
  const _StaffDirectory({required this.businessId});

  final String businessId;

  static const Color _primary = Color(0xFF176B52);

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    final members = firestore
        .collection('businesses')
        .doc(businessId)
        .collection('members');

    final requests = firestore
        .collection('joinRequests')
        .where('businessId', isEqualTo: businessId)
        .where('status', isEqualTo: 'pending');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: members.snapshots(),
      builder: (context, memberSnapshot) {
        if (memberSnapshot.hasError) {
          return const _MessageView(
            icon: Icons.cloud_off_outlined,
            title: 'Team data unavailable',
            message: 'Check your Firestore membership permissions.',
          );
        }

        if (memberSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final staff = (memberSnapshot.data?.docs ?? [])
            .where((doc) => doc.data()['role'] == 'staff')
            .toList();

        final activeCount = staff
            .where((doc) => doc.data()['status'] == 'active')
            .length;

        final disabledCount = staff
            .where((doc) => doc.data()['status'] == 'disabled')
            .length;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: requests.snapshots(),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.hasError) {
              return const _MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'Requests unavailable',
                message:
                    'Staff requests cannot be loaded yet. Firestore '
                    'security rules must allow owners to read requests '
                    'for their business.',
              );
            }

            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final pendingRequests = requestSnapshot.data?.docs ?? [];

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.groups_rounded, color: Colors.white, size: 34),
                      SizedBox(height: 16),
                      Text(
                        'Manage your team',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Review staff requests and manage your business team.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TEAM OVERVIEW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total staff',
                        value: '${staff.length}',
                        icon: Icons.people_outline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Active',
                        value: '$activeCount',
                        icon: Icons.verified_user_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Disabled',
                        value: '$disabledCount',
                        icon: Icons.person_off_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'PENDING REQUESTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                if (pendingRequests.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'There are no staff requests awaiting review.',
                      ),
                    ),
                  )
                else
                  ...pendingRequests.map((doc) {
                    final data = doc.data();
                    final email = data['email'] as String? ?? 'Unknown email';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_add_alt_1),
                              ),
                              title: Text(
                                email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: const Text('Awaiting owner approval'),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _reviewRequest(
                                      context,
                                      doc.id,
                                      approve: false,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _reviewRequest(
                                      context,
                                      doc.id,
                                      approve: true,
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                const Text(
                  'YOUR STAFF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                if (staff.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No staff members yet.'),
                    ),
                  )
                else
                  ...staff.map((doc) {
                    final data = doc.data();
                    final email = data['email'] as String? ?? 'No email';
                    final status = data['status'] as String? ?? 'unknown';
                    final isActive = status == 'active';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE1F1EA),
                                child: Text(
                                  email.isNotEmpty
                                      ? email[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text('Role: staff'),
                              trailing: _StatusChip(status: status),
                            ),
                            const Divider(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed:
                                    status == 'active' || status == 'disabled'
                                    ? () => _changeStaffStatus(
                                        context,
                                        doc.id,
                                        email,
                                        disable: isActive,
                                      )
                                    : null,
                                icon: Icon(
                                  isActive
                                      ? Icons.person_off_outlined
                                      : Icons.person_outline_rounded,
                                ),
                                label: Text(
                                  isActive
                                      ? 'Disable access'
                                      : 'Re-enable access',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isActive
                                      ? Colors.red.shade700
                                      : _primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _reviewRequest(
    BuildContext context,
    String requestId, {
    required bool approve,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          approve ? 'Approve staff request?' : 'Reject staff request?',
        ),
        content: Text(
          approve
              ? 'This will create an active staff membership.'
              : 'This staff request will be marked as rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final service = StaffApprovalService();

      if (approve) {
        await service.approveRequest(requestId);
      } else {
        await service.rejectRequest(requestId);
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Staff member approved.' : 'Request rejected.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not ${approve ? 'approve' : 'reject'} request: $error',
          ),
        ),
      );
    }
  }

  Future<void> _changeStaffStatus(
    BuildContext context,
    String staffUid,
    String email, {
    required bool disable,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          disable ? 'Disable staff access?' : 'Re-enable staff access?',
        ),
        content: Text(
          disable
              ? 'This will prevent $email from accessing the business '
                    'dashboard. Their account and records will be retained.'
              : 'This will restore $email access to the business dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: disable
                ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700)
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(disable ? 'Disable access' : 'Re-enable'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await StaffApprovalService().setStaffStatus(
        staffUid: staffUid,
        status: disable ? 'disabled' : 'active',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            disable ? 'Staff access disabled.' : 'Staff access re-enabled.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not ${disable ? 'disable' : 're-enable'} staff access: '
            '$error',
          ),
        ),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF176B52), size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final Color color;
    final Color textColor;

    switch (normalized) {
      case 'active':
        color = Colors.green;
        textColor = Colors.green.shade700;
        break;
      case 'pending':
        color = Colors.orange;
        textColor = Colors.orange.shade700;
        break;
      case 'disabled':
        color = Colors.red;
        textColor = Colors.red.shade700;
        break;
      default:
        color = Colors.grey;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF176B52)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
