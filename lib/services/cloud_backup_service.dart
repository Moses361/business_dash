import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database/database_service.dart';

class CloudBackupService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final DatabaseService _database;

  CloudBackupService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DatabaseService? database,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _database = database ?? DatabaseService();

  Future<Map<String, dynamic>> uploadBackup() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in before creating a cloud backup.');
    }

    // Only approved business owners may create cloud backups.
    final profile = await _firestore.collection('users').doc(user.uid).get();

    if (profile.data()?['role'] != 'owner') {
      throw StateError('Only an approved owner can create cloud backups.');
    }

    final filePath = await _database.exportDatabase();
    final file = File(filePath);

    try {
      final decoded = jsonDecode(await file.readAsString());

      if (decoded is! Map) {
        throw const FormatException('Invalid backup: expected a JSON object.');
      }

      final backup = Map<String, dynamic>.from(decoded);

      if (backup['format'] != 'veroon_json_backup' ||
          backup['formatVersion'] != 1) {
        throw const FormatException('Unsupported Veroon backup format.');
      }

      final backupId = DateTime.now().toUtc().millisecondsSinceEpoch.toString();

      final backupRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc(backupId);

      final rawCounts = backup['counts'];

      if (rawCounts is! Map) {
        throw const FormatException('Invalid backup: missing record counts.');
      }

      final counts = Map<String, dynamic>.from(rawCounts);

      // Include inventory history alongside products, sales, and expenses.
      final collectionNames = <String>[
        'products',
        'sales',
        'expenses',
        'inventory_movements',
      ];

      // Validate that all collections exist before starting the upload.
      for (final collectionName in collectionNames) {
        if (backup[collectionName] is! List) {
          throw FormatException(
            'Invalid backup: $collectionName must be a list.',
          );
        }
      }

      await backupRef.set({
        'backupId': backupId,
        'ownerUid': user.uid,
        'status': 'uploading',
        'format': backup['format'],
        'formatVersion': backup['formatVersion'],
        'databaseVersion': backup['databaseVersion'],
        'exportedAt': backup['exportedAt'],
        'counts': counts,
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        for (final collectionName in collectionNames) {
          final records = backup[collectionName] as List<dynamic>;

          var batch = _firestore.batch();
          var pendingWrites = 0;

          for (final item in records) {
            if (item is! Map) {
              throw FormatException('Invalid record in $collectionName.');
            }

            final record = Map<String, dynamic>.from(item);
            final recordId = record['id'];

            if (recordId == null) {
              throw FormatException('A $collectionName record has no ID.');
            }

            final recordRef = backupRef
                .collection(collectionName)
                .doc('record_$recordId');

            batch.set(recordRef, record);
            pendingWrites++;

            // Firestore permits at most 500 writes per batch.
            // Keep each batch below that limit.
            if (pendingWrites == 400) {
              await batch.commit();

              batch = _firestore.batch();
              pendingWrites = 0;
            }
          }

          if (pendingWrites > 0) {
            await batch.commit();
          }
        }

        await backupRef.update({
          'status': 'complete',
          'completedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        try {
          await backupRef.update({'status': 'failed'});
        } catch (_) {
          // Preserve the original upload error.
        }

        rethrow;
      }

      return {'backupId': backupId, 'counts': counts};
    } finally {
      // Delete the temporary export file after the upload attempt.
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
