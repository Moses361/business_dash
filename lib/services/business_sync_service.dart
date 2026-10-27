import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_service.dart';
import 'business_membership_service.dart';

/// Synchronizes records for one verified Veroon business.
///
/// Do not enable live synchronization until Firestore rules and the initial
/// business-data bootstrap have been tested.
class BusinessSyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final DatabaseService _databaseService;
  final BusinessMembershipService _membershipService;

  BusinessSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    DatabaseService? databaseService,
    BusinessMembershipService? membershipService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _databaseService = databaseService ?? DatabaseService(),
       _membershipService = membershipService ?? BusinessMembershipService();

  Future<Map<String, dynamic>> syncNow() async {
    if (_auth.currentUser == null) {
      throw StateError('Please sign in before synchronizing.');
    }

    final membership = await _membershipService.getCurrentMembership();
    final businessId = membership['businessId'];

    if (businessId is! String || businessId.trim().isEmpty) {
      throw StateError('A valid business membership is required.');
    }

    final db = await _databaseService.database;

    final downloaded = <String, int>{};
    final uploaded = <String, int>{};

    // Products first: sales need their product_sync_id to resolve locally.
    for (final name in [
      DatabaseService.productsTable,
      DatabaseService.expensesTable,
      DatabaseService.salesTable,
    ]) {
      downloaded[name] = await _downloadCollection(
        db: db,
        businessId: businessId,
        collectionName: name,
      );
    }

    for (final name in [
      DatabaseService.productsTable,
      DatabaseService.expensesTable,
      DatabaseService.salesTable,
    ]) {
      uploaded[name] = await _uploadPending(
        db: db,
        businessId: businessId,
        collectionName: name,
      );
    }

    return {
      'businessId': businessId,
      'downloaded': {
        ...downloaded,
        'total': downloaded.values.fold<int>(
          0,
          (runningTotal, itemValue) => runningTotal + itemValue,
        ),
      },
      'uploaded': {
        ...uploaded,
        'total': uploaded.values.fold<int>(
          0,
          (runningTotal, itemValue) => runningTotal + itemValue,
        ),
      },
      'completedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<int> _uploadPending({
    required Database db,
    required String businessId,
    required String collectionName,
  }) async {
    final rows = await db.query(
      collectionName,
      where: "${DatabaseService.syncStatusColumn} = ?",
      whereArgs: ['pending'],
      orderBy: 'id ASC',
    );

    var count = 0;
    final collection = _businessCollection(businessId, collectionName);

    for (final row in rows) {
      final syncId = row[DatabaseService.syncIdColumn];
      if (syncId is! String || syncId.isEmpty) {
        throw StateError('$collectionName record is missing its sync ID.');
      }

      final localTime = _parseTime(row[DatabaseService.updatedAtColumn]);
      if (localTime == null) {
        throw StateError('$collectionName record has an invalid updated_at.');
      }

      final document = collection.doc(syncId);
      final remoteSnapshot = await document.get();

      if (remoteSnapshot.exists) {
        final remote = remoteSnapshot.data()!;
        final remoteTime = _parseTime(remote[DatabaseService.updatedAtColumn]);

        // Never overwrite a record that is newer in the cloud.
        if (remoteTime != null && remoteTime.isAfter(localTime)) {
          final applied = await _applyRemoteRecord(
            db: db,
            collectionName: collectionName,
            syncId: syncId,
            cloud: remote,
          );

          // If a sale cannot yet resolve its product, keep it pending.
          if (!applied) {
            continue;
          }
          continue;
        }

        // Equal timestamps with different contents are ambiguous. Keep the
        // local record pending rather than silently choosing one.
        if (remoteTime != null && remoteTime.isAtSameMomentAs(localTime)) {
          final localPayload = _toCloudRecord(row, collectionName);
          if (!_sameRecord(remote, localPayload)) {
            continue;
          }
        }
      }

      await document.set(_toCloudRecord(row, collectionName));

      await db.update(
        collectionName,
        {DatabaseService.syncStatusColumn: 'synced'},
        where:
            '${DatabaseService.syncIdColumn} = ? AND '
            '${DatabaseService.syncStatusColumn} = ?',
        whereArgs: [syncId, 'pending'],
      );

      count++;
    }

    return count;
  }

  Future<int> _downloadCollection({
    required Database db,
    required String businessId,
    required String collectionName,
  }) async {
    final snapshot = await _businessCollection(
      businessId,
      collectionName,
    ).get();

    var count = 0;

    for (final document in snapshot.docs) {
      final applied = await _applyRemoteRecord(
        db: db,
        collectionName: collectionName,
        syncId: document.id,
        cloud: document.data(),
      );

      if (applied) count++;
    }

    return count;
  }

  Future<bool> _applyRemoteRecord({
    required Database db,
    required String collectionName,
    required String syncId,
    required Map<String, dynamic> cloud,
  }) async {
    final cloudTime = _parseTime(cloud[DatabaseService.updatedAtColumn]);
    if (cloudTime == null) return false;

    final localRows = await db.query(
      collectionName,
      where: '${DatabaseService.syncIdColumn} = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    final local = localRows.isEmpty ? null : localRows.first;

    // Protect unsynchronized local edits.
    if (local != null && local[DatabaseService.syncStatusColumn] == 'pending') {
      return false;
    }

    if (local != null) {
      final localTime = _parseTime(local[DatabaseService.updatedAtColumn]);
      if (localTime != null && !cloudTime.isAfter(localTime)) {
        return false;
      }
    }

    final record = await _fromCloudRecord(
      db: db,
      cloud: cloud,
      collectionName: collectionName,
      syncId: syncId,
    );

    // Missing products or malformed records must never create broken sales.
    if (record == null) return false;

    if (local == null) {
      await db.insert(collectionName, record);
    } else {
      await db.update(
        collectionName,
        record,
        where: '${DatabaseService.syncIdColumn} = ?',
        whereArgs: [syncId],
      );
    }

    return true;
  }

  CollectionReference<Map<String, dynamic>> _businessCollection(
    String businessId,
    String collectionName,
  ) {
    const allowed = {
      DatabaseService.productsTable,
      DatabaseService.salesTable,
      DatabaseService.expensesTable,
    };

    if (!allowed.contains(collectionName)) {
      throw ArgumentError.value(collectionName, 'collectionName');
    }

    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection(collectionName);
  }

  Map<String, dynamic> _toCloudRecord(
    Map<String, Object?> row,
    String collectionName,
  ) {
    final record = Map<String, dynamic>.from(row);
    record.remove('id');

    if (collectionName == DatabaseService.salesTable) {
      record.remove('product_id');
    }

    record[DatabaseService.syncStatusColumn] = 'synced';
    return record;
  }

  Future<Map<String, Object?>?> _fromCloudRecord({
    required Database db,
    required Map<String, dynamic> cloud,
    required String collectionName,
    required String syncId,
  }) async {
    final updatedAt = cloud[DatabaseService.updatedAtColumn];
    final deletedAt = cloud[DatabaseService.deletedAtColumn];

    final record = <String, Object?>{
      DatabaseService.syncIdColumn: syncId,
      DatabaseService.syncStatusColumn: 'synced',
      DatabaseService.updatedAtColumn: updatedAt.toString(),
      DatabaseService.deletedAtColumn: deletedAt?.toString(),
    };

    if (collectionName == DatabaseService.productsTable) {
      if (cloud['name'] is! String ||
          cloud['category'] is! String ||
          cloud['buying_price'] is! num ||
          cloud['selling_price'] is! num ||
          cloud['stock_quantity'] is! num) {
        return null;
      }

      record.addAll({
        'name': cloud['name'],
        'category': cloud['category'],
        'buying_price': (cloud['buying_price'] as num).toDouble(),
        'selling_price': (cloud['selling_price'] as num).toDouble(),
        'stock_quantity': (cloud['stock_quantity'] as num).toInt(),
      });
    } else if (collectionName == DatabaseService.expensesTable) {
      if (cloud['title'] is! String ||
          cloud['category'] is! String ||
          cloud['amount'] is! num ||
          cloud['created_at'] == null) {
        return null;
      }

      record.addAll({
        'title': cloud['title'],
        'amount': (cloud['amount'] as num).toDouble(),
        'category': cloud['category'],
        'created_at': cloud['created_at'].toString(),
      });
    } else if (collectionName == DatabaseService.salesTable) {
      final productSyncId = cloud['product_sync_id'];
      if (productSyncId is! String ||
          cloud['product_name'] is! String ||
          cloud['quantity'] is! num ||
          cloud['buying_price'] is! num ||
          cloud['selling_price'] is! num ||
          cloud['total_amount'] is! num ||
          cloud['created_at'] == null) {
        return null;
      }

      final products = await db.query(
        DatabaseService.productsTable,
        columns: ['id'],
        where: '${DatabaseService.syncIdColumn} = ?',
        whereArgs: [productSyncId],
        limit: 1,
      );

      // Do not create a sale before its product exists locally.
      if (products.isEmpty) return null;

      record.addAll({
        'product_id': products.first['id'],
        'product_sync_id': productSyncId,
        'product_name': cloud['product_name'],
        'quantity': (cloud['quantity'] as num).toInt(),
        'buying_price': (cloud['buying_price'] as num).toDouble(),
        'selling_price': (cloud['selling_price'] as num).toDouble(),
        'total_amount': (cloud['total_amount'] as num).toDouble(),
        'created_at': cloud['created_at'].toString(),
      });
    } else {
      return null;
    }

    return record;
  }

  DateTime? _parseTime(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  bool _sameRecord(Map<String, dynamic> remote, Map<String, dynamic> local) {
    const ignored = {'id'};
    for (final key in local.keys) {
      if (ignored.contains(key)) continue;
      if (remote[key] != local[key]) return false;
    }
    return true;
  }
}
