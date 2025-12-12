import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/user_db.dart';

/// Repository class for managing User database operations.
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Inserts a new user into the database.
  Future<int> insert(UserDB user) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'user',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Gets a user by ID (excluding soft-deleted users).
  Future<UserDB?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'user',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return UserDB.fromMap(maps.first);
  }

  /// Gets all users (excluding soft-deleted users).
  Future<List<UserDB>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'user',
      where: 'is_deleted = 0',
      orderBy: 'username ASC',
    );

    return maps.map((map) => UserDB.fromMap(map)).toList();
  }

  /// Updates an existing user.
  Future<int> update(UserDB user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'user',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Soft deletes a user by setting is_deleted flag.
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'user',
      {
        'is_deleted': 1,
        'modified_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hard deletes a user from the database (permanent).
  Future<int> hardDelete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'user',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Gets all users including soft-deleted ones.
  Future<List<UserDB>> getAllIncludingDeleted() async {
    final db = await _dbHelper.database;
    final maps = await db.query('user', orderBy: 'username ASC');
    return maps.map((map) => UserDB.fromMap(map)).toList();
  }

  /// Deletes all users from the database.
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('user');
  }
}
