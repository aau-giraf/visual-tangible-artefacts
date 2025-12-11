import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/saved_artefact_db.dart';

/// Repository class for managing SavedArtefact database operations.
class SavedArtefactRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Inserts a new saved artefact into the database.
  Future<int> insert(SavedArtefactDB savedArtefact) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'saved_artefact',
      savedArtefact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Gets a saved artefact by ID (excluding soft-deleted).
  Future<SavedArtefactDB?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saved_artefact',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return SavedArtefactDB.fromMap(maps.first);
  }

  /// Gets all saved artefacts for a specific board (excluding soft-deleted).
  Future<List<SavedArtefactDB>> getByBoardId(String boardId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saved_artefact',
      where: 'board_id = ? AND is_deleted = 0',
      whereArgs: [boardId],
      orderBy: 'created_date ASC',
    );

    return maps.map((map) => SavedArtefactDB.fromMap(map)).toList();
  }

  /// Gets all saved artefacts for a specific artefact ID (excluding soft-deleted).
  Future<List<SavedArtefactDB>> getByArtefactId(String artefactId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saved_artefact',
      where: 'artefact_id = ? AND is_deleted = 0',
      whereArgs: [artefactId],
    );

    return maps.map((map) => SavedArtefactDB.fromMap(map)).toList();
  }

  /// Gets all saved artefacts (excluding soft-deleted).
  Future<List<SavedArtefactDB>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saved_artefact',
      where: 'is_deleted = 0',
    );

    return maps.map((map) => SavedArtefactDB.fromMap(map)).toList();
  }

  /// Updates an existing saved artefact.
  Future<int> update(SavedArtefactDB savedArtefact) async {
    final db = await _dbHelper.database;
    return await db.update(
      'saved_artefact',
      savedArtefact.toMap(),
      where: 'id = ?',
      whereArgs: [savedArtefact.id],
    );
  }

  /// Updates the position of a saved artefact.
  Future<int> updatePosition(String id, double posX, double posY) async {
    final db = await _dbHelper.database;
    return await db.update(
      'saved_artefact',
      {
        'pos_x': posX,
        'pos_y': posY,
        'modified_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Updates the size of a saved artefact.
  Future<int> updateSize(String id, double width, double height) async {
    final db = await _dbHelper.database;
    return await db.update(
      'saved_artefact',
      {
        'width': width,
        'height': height,
        'modified_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Soft deletes a saved artefact by setting is_deleted flag.
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'saved_artefact',
      {
        'is_deleted': 1,
        'modified_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all saved artefacts for a specific board.
  Future<int> deleteByBoardId(String boardId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'saved_artefact',
      {
        'is_deleted': 1,
        'modified_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'board_id = ?',
      whereArgs: [boardId],
    );
  }

  /// Hard deletes a saved artefact from the database (permanent).
  Future<int> hardDelete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'saved_artefact',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all saved artefacts from the database.
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('saved_artefact');
  }

  /// Batch insert multiple saved artefacts.
  Future<void> insertBatch(List<SavedArtefactDB> savedArtefacts) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    
    for (final savedArtefact in savedArtefacts) {
      batch.insert(
        'saved_artefact',
        savedArtefact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }
}
