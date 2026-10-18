import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../database/database_service.dart';

import '../services/cloud_backup_service.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  final CloudBackupService _backupService = CloudBackupService();
  final DatabaseService _databaseService = DatabaseService();

  bool _busy = false;
  String? _message;
  bool _success = false;

  Future<void> _createBackup() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final result = await _backupService.uploadBackup();
      final counts = Map<String, dynamic>.from(result['counts'] as Map);

      if (!mounted) return;

      setState(() {
        _success = true;
        _message =
            'Cloud backup completed successfully.\n\n'
            'Products: ${counts['products']}\n'
            'Sales: ${counts['sales']}\n'
            'Expenses: ${counts['expenses']}\n\n'
            'Backup ID: ${result['backupId']}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _success = false;
        _message = 'Backup failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _importBackup() async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (!mounted || selection.isEmpty) return;

    final path = selection.first.path;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access the selected file.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace local business data?'),
        content: const Text(
          'Importing this backup replaces the products, sales, and expenses '
          'currently stored on this device. A safety backup will be created '
          'first. Continue only if you trust this backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore backup'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final result = await _databaseService.restoreDatabase(path);
      if (!mounted) return;

      setState(() {
        _success = true;
        _message =
            'Backup restored successfully.\n\n'
            'Products: ${result['products']}\n'
            'Sales: ${result['sales']}\n'
            'Expenses: ${result['expenses']}\n\n'
            'Safety copy: ${result['safetyBackupPath']}\n\n'
            'Return to the relevant screen to refresh its displayed data.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message =
            'Import failed; your database was not replaced if '
            'validation failed or the transaction rolled back.\n$error';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Backup')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            'Back up your business records',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Create a cloud snapshot of your products, sales, '
            'and expenses. Your existing local database stays '
            'in place. This feature uploads backups; it does '
            'not yet synchronize changes automatically.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _createBackup,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(_busy ? 'Creating backup...' : 'Back up now'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _importBackup,
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Import backup'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 20),
            SelectableText(
              _message!,
              style: TextStyle(
                color: _success
                    ? Colors.green.shade700
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
