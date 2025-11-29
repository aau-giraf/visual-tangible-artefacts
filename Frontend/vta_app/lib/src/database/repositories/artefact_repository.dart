import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/artefact_db.dart';

/// Repository class for managing Artefact database operations.
class ArtefactRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Inserts a new artefact into the database.
  Future<int> insert(ArtefactDB artefact) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'artefact',
      artefact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Gets an artefact by ID (excluding soft-deleted artefacts).
  Future<ArtefactDB?> getById(String artefactId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'artefact',
      where: 'artefact_id = ? AND is_deleted = 0',
      whereArgs: [artefactId],
    );

    if (maps.isEmpty) return null;
    return ArtefactDB.fromMap(maps.first);
  }

  /// Gets all artefacts for a specific user (excluding soft-deleted).
  Future<List<ArtefactDB>> getByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'artefact',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'artefact_index ASC',
    );

    return maps.map((map) => ArtefactDB.fromMap(map)).toList();
  }

  /// Gets all artefacts for a specific category (excluding soft-deleted).
  Future<List<ArtefactDB>> getByCategoryId(String categoryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'artefact',
      where: 'category_id = ? AND is_deleted = 0',
      whereArgs: [categoryId],
      orderBy: 'artefact_index ASC',
    );

    return maps.map((map) => ArtefactDB.fromMap(map)).toList();
  }

  /// Gets all artefacts (excluding soft-deleted).
  Future<List<ArtefactDB>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'artefact',
      where: 'is_deleted = 0',
      orderBy: 'artefact_index ASC',
    );

    return maps.map((map) => ArtefactDB.fromMap(map)).toList();
  }

  /// Updates an existing artefact.
  Future<int> update(ArtefactDB artefact) async {
    final db = await _dbHelper.database;
    return await db.update(
      'artefact',
      artefact.toMap(),
      where: 'artefact_id = ?',
      whereArgs: [artefact.artefactId],
    );
  }

  /// Soft deletes an artefact by setting is_deleted flag.
  Future<int> delete(String artefactId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'artefact',
      {
        'is_deleted': 1,
        'modified_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'artefact_id = ?',
      whereArgs: [artefactId],
    );
  }

  /// Gets artefacts by name search (excluding soft-deleted).
  Future<List<ArtefactDB>> searchByName(String userId, String searchTerm) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'artefact',
      where: 'user_id = ? AND is_deleted = 0 AND name LIKE ?',
      whereArgs: [userId, '%$searchTerm%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => ArtefactDB.fromMap(map)).toList();
  }

  /// Gets artefacts by multiple IDs (excluding soft-deleted).
  Future<List<ArtefactDB>> getByIds(List<String> artefactIds) async {
    if (artefactIds.isEmpty) return [];
    
    final db = await _dbHelper.database;
    final placeholders = List.filled(artefactIds.length, '?').join(',');
    final maps = await db.query(
      'artefact',
      where: 'artefact_id IN ($placeholders) AND is_deleted = 0',
      whereArgs: artefactIds,
    );

    return maps.map((map) => ArtefactDB.fromMap(map)).toList();
  }

  /// Hard deletes an artefact from the database (permanent).
  Future<int> hardDelete(String artefactId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'artefact',
      where: 'artefact_id = ?',
      whereArgs: [artefactId],
    );
  }

  /// Deletes all artefacts for a specific category.
  Future<int> deleteByCategory(String categoryId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'artefact',
      {
        'is_deleted': 1,
        'modified_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  /// Deletes all artefacts from the database.
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('artefact');
  }
}
