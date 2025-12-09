import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/session_meta_db.dart';

/// Repository class for managing SessionMeta database operations.
class SessionMetaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Inserts a new session meta record into the database.
  Future<int> insert(SessionMetaDB sessionMeta) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'session_meta',
      sessionMeta.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Gets a session meta record by ID.
  Future<SessionMetaDB?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'session_meta',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return SessionMetaDB.fromMap(maps.first);
  }

  /// Gets a session meta record by session ID.
  Future<SessionMetaDB?> getBySessionId(String sessionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'session_meta',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isEmpty) return null;
    return SessionMetaDB.fromMap(maps.first);
  }

  /// Gets all session meta records for a specific board.
  Future<List<SessionMetaDB>> getByBoardId(String boardId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'session_meta',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'started_at DESC',
    );

    return maps.map((map) => SessionMetaDB.fromMap(map)).toList();
  }

  /// Gets all session meta records for a specific user.
  Future<List<SessionMetaDB>> getByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'session_meta',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'started_at DESC',
    );

    return maps.map((map) => SessionMetaDB.fromMap(map)).toList();
  }

  /// Gets all dirty sessions (sessions with unsynced changes).
  Future<List<SessionMetaDB>> getDirtySessions() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'session_meta',
      where: 'is_dirty = 1',
      orderBy: 'started_at ASC',
    );

    return maps.map((map) => SessionMetaDB.fromMap(map)).toList();
  }

  /// Gets all session meta records.
  Future<List<SessionMetaDB>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'session_meta',
      orderBy: 'started_at DESC',
    );

    return maps.map((map) => SessionMetaDB.fromMap(map)).toList();
  }

  /// Updates an existing session meta record.
  Future<int> update(SessionMetaDB sessionMeta) async {
    final db = await _dbHelper.database;
    return await db.update(
      'session_meta',
      sessionMeta.toMap(),
      where: 'id = ?',
      whereArgs: [sessionMeta.id],
    );
  }

  /// Marks a session as synced (clears the dirty flag).
  Future<int> markAsSynced(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'session_meta',
      {
        'is_dirty': 0,
        'last_synced_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marks a session as dirty (has unsynced changes).
  Future<int> markAsDirty(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'session_meta',
      {'is_dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a session meta record (permanent).
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'session_meta',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all session meta records for a specific board.
  Future<int> deleteByBoardId(String boardId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'session_meta',
      where: 'board_id = ?',
      whereArgs: [boardId],
    );
  }

  /// Deletes old synced sessions (cleanup).
  Future<int> deleteOldSyncedSessions(int olderThanTimestamp) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'session_meta',
      where: 'is_dirty = 0 AND last_synced_at < ?',
      whereArgs: [olderThanTimestamp],
    );
  }

  /// Deletes all session meta records from the database.
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('session_meta');
  }
}
