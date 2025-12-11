import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/sync_metadata_db.dart';

/// Repository class for managing sync metadata database operations.
class SyncMetadataRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Inserts or updates sync metadata for a user and entity type.
  Future<int> upsert(SyncMetadataDB metadata) async {
    final db = await _dbHelper.database;
    
    // Try to update first
    final updated = await db.update(
      'sync_metadata',
      metadata.toMap(),
      where: 'user_id = ? AND entity_type = ?',
      whereArgs: [metadata.userId, metadata.entityType],
    );

    // If no rows were updated, insert instead
    if (updated == 0) {
      return await db.insert(
        'sync_metadata',
        metadata.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    return updated;
  }

  /// Gets sync metadata for a specific user and entity type.
  Future<SyncMetadataDB?> get(String userId, String entityType) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'sync_metadata',
      where: 'user_id = ? AND entity_type = ?',
      whereArgs: [userId, entityType],
    );

    if (maps.isEmpty) return null;
    return SyncMetadataDB.fromMap(maps.first);
  }

  /// Gets all sync metadata for a specific user.
  Future<List<SyncMetadataDB>> getByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'sync_metadata',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return maps.map((map) => SyncMetadataDB.fromMap(map)).toList();
  }

  /// Gets the last sync date for a specific user and entity type.
  /// Returns null if no sync has been performed.
  Future<DateTime?> getLastSyncDate(String userId, String entityType) async {
    final metadata = await get(userId, entityType);
    if (metadata == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(metadata.lastSyncDate * 1000);
  }

  /// Updates the last sync date for a specific user and entity type.
  Future<void> updateLastSyncDate(
    String userId,
    String entityType,
    DateTime syncDate,
  ) async {
    final existingMetadata = await get(userId, entityType);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final syncTimestamp = syncDate.millisecondsSinceEpoch ~/ 1000;

    if (existingMetadata != null) {
      await upsert(existingMetadata.copyWith(
        lastSyncDate: syncTimestamp,
        lastCheckDate: now,
      ));
    } else {
      await upsert(SyncMetadataDB(
        userId: userId,
        entityType: entityType,
        lastSyncDate: syncTimestamp,
        lastCheckDate: now,
      ));
    }
  }

  /// Updates the last check date without updating sync date.
  Future<void> updateLastCheckDate(String userId, String entityType) async {
    final existingMetadata = await get(userId, entityType);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (existingMetadata != null) {
      await upsert(existingMetadata.copyWith(lastCheckDate: now));
    } else {
      // If no metadata exists, create one with sync date set to now
      await upsert(SyncMetadataDB(
        userId: userId,
        entityType: entityType,
        lastSyncDate: now,
        lastCheckDate: now,
      ));
    }
  }

  /// Deletes sync metadata for a specific user and entity type.
  Future<int> delete(String userId, String entityType) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'sync_metadata',
      where: 'user_id = ? AND entity_type = ?',
      whereArgs: [userId, entityType],
    );
  }

  /// Deletes all sync metadata for a specific user.
  Future<int> deleteByUserId(String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'sync_metadata',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Deletes all sync metadata from the database.
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('sync_metadata');
  }
}
