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

    final profile = await _firestore.collection('users').doc(user.uid).get();

    if (profile.data()?['role'] != 'owner') {
      throw StateError('Only an approved owner can create cloud backups.');
    }

    final filePath = await _database.exportDatabase();
    final file = File(filePath);

    try {
      final backup =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      final backupId = DateTime.now().toUtc().millisecondsSinceEpoch.toString();

      final backupRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc(backupId);

      final counts = Map<String, dynamic>.from(backup['counts'] as Map);

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
        for (final collectionName in ['products', 'sales', 'expenses']) {
          final records = backup[collectionName] as List<dynamic>;
          var batch = _firestore.batch();
          var pendingWrites = 0;

          for (final item in records) {
            final record = Map<String, dynamic>.from(item as Map);
            final recordId = record['id'];

            if (recordId == null) {
              throw FormatException('A $collectionName record has no ID.');
            }

            final recordRef = backupRef
                .collection(collectionName)
                .doc('record_$recordId');

            batch.set(recordRef, record);
            pendingWrites++;

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
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
