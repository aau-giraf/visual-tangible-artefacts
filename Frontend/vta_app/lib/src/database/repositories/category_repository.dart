import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/category_db.dart';

/// Repository class for managing Category database operations.
class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Inserts a new category into the database.
  Future<int> insert(CategoryDB category) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'category',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Gets a category by ID (excluding soft-deleted categories).
  Future<CategoryDB?> getById(String categoryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'category',
      where: 'category_id = ? AND is_deleted = 0',
      whereArgs: [categoryId],
    );

    if (maps.isEmpty) return null;
    return CategoryDB.fromMap(maps.first);
  }

  /// Gets all categories for a specific user (excluding soft-deleted).
  Future<List<CategoryDB>> getByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'category',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'category_index ASC',
    );

    return maps.map((map) => CategoryDB.fromMap(map)).toList();
  }

  /// Gets all categories (excluding soft-deleted).
  Future<List> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'category',
      where: 'is_deleted = 0',
      orderBy: 'category_index ASC',
    );

    return maps.map((map) => CategoryDB.fromMap(map)).toList();
  }

  /// Updates an existing category.
  Future<int> update(CategoryDB category) async {
    final db = await _dbHelper.database;
    return await db.update(
      'category',
      category.toMap(),
      where: 'category_id = ?',
      whereArgs: [category.categoryId],
    );
  }

  /// Soft deletes a category by setting is_deleted flag.
  Future<int> delete(String categoryId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'category',
      {
        'is_deleted': 1,
        'modified_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  /// Increments the usage count for a category.
  Future<int> incrementUsageCount(String categoryId) async {
    final db = await _dbHelper.database;
    return await db.rawUpdate(
      'UPDATE category SET usage_count = usage_count + 1, last_used_date = ? WHERE category_id = ?',
      [DateTime.now().millisecondsSinceEpoch ~/ 1000, categoryId],
    );
  }

  /// Gets categories sorted by most recently used.
  Future<List<CategoryDB>> getMostRecentlyUsed(String userId, {int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'category',
      where: 'user_id = ? AND is_deleted = 0 AND last_used_date IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'last_used_date DESC',
      limit: limit,
    );

    return maps.map((map) => CategoryDB.fromMap(map)).toList();
  }

  /// Gets categories sorted by usage count.
  Future<List<CategoryDB>> getMostUsed(String userId, {int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'category',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'usage_count DESC',
      limit: limit,
    );

    return maps.map((map) => CategoryDB.fromMap(map)).toList();
  }

  /// Hard deletes a category from the database (permanent).
  Future<int> hardDelete(String categoryId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'category',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  /// Deletes all categories from the database.
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('category');
  }
}
