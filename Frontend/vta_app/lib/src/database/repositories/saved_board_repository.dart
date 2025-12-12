import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/saved_board_db.dart';

/// Repository class for managing SavedBoard database operations.
class SavedBoardRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Inserts a new saved board into the database.
  Future<int> insert(SavedBoardDB board) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'saved_board',
      board.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Gets a saved board by ID (excluding soft-deleted boards).
  Future<SavedBoardDB?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saved_board',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return SavedBoardDB.fromMap(maps.first);
  }

  /// Gets all saved boards for a specific user (excluding soft-deleted).
  Future<List<SavedBoardDB>> getByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saved_board',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'modified_date DESC',
    );

    return maps.map((map) => SavedBoardDB.fromMap(map)).toList();
  }

  /// Gets all saved boards (excluding soft-deleted).
  Future<List<SavedBoardDB>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saved_board',
      where: 'is_deleted = 0',
      orderBy: 'modified_date DESC',
    );

    return maps.map((map) => SavedBoardDB.fromMap(map)).toList();
  }

  /// Updates an existing saved board.
  Future<int> update(SavedBoardDB board) async {
    final db = await _dbHelper.database;
    return await db.update(
      'saved_board',
      board.toMap(),
      where: 'id = ?',
      whereArgs: [board.id],
    );
  }

  /// Soft deletes a saved board by setting is_deleted flag.
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'saved_board',
      {
        'is_deleted': 1,
        'modified_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Searches saved boards by name for a specific user.
  Future<List<SavedBoardDB>> searchByName(String userId, String searchTerm) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saved_board',
      where: 'user_id = ? AND is_deleted = 0 AND name LIKE ?',
      whereArgs: [userId, '%$searchTerm%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => SavedBoardDB.fromMap(map)).toList();
  }

  /// Gets the most recently modified boards for a user.
  Future<List<SavedBoardDB>> getRecentBoards(String userId, {int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saved_board',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'modified_date DESC',
      limit: limit,
    );

    return maps.map((map) => SavedBoardDB.fromMap(map)).toList();
  }

  /// Hard deletes a saved board from the database (permanent).
  Future<int> hardDelete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'saved_board',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all saved boards from the database.
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('saved_board');
  }
}
