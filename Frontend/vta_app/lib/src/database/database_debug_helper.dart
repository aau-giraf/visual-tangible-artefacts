
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database.dart';
import 'package:logging/logging.dart';


final _log = Logger('DatabaseDebugHelper');
/// Debug helper class for viewing and managing SQLite database during development.
class DatabaseDebugHelper {
  /// Prints all data from all tables in the database.
  static Future<void> printAllData() async {
    _log.info('\n=== 📊 DATABASE CONTENTS ===\n');
    
    try {
      // Users
      final users = await UserRepository().getAll();
      _log.info('👥 Users (${users.length}):');
      if (users.isEmpty) {
        _log.info('  (No users found)');
      } else {
        for (final user in users) {
          _log.info('  - ${user.toString()}');
        }
      }
      
      // Categories
      final categories = await CategoryRepository().getAll();
      _log.info('\n📁 Categories (${categories.length}):');
      if (categories.isEmpty) {
        _log.info('  (No categories found)');
      } else {
        for (final category in categories) {
          _log.info('  - ${category.toString()}');
        }
      }
      
      // Artefacts
      final artefacts = await ArtefactRepository().getAll();
      _log.info('\n🎨 Artefacts (${artefacts.length}):');
      if (artefacts.isEmpty) {
        _log.info('  (No artefacts found)');
      } else {
        for (final artefact in artefacts) {
          _log.info('  - ${artefact.toString()}');
        }
      }
      
      // Boards
      final boards = await SavedBoardRepository().getAll();
      _log.info('\n📋 Boards (${boards.length}):');
      if (boards.isEmpty) {
        _log.info('  (No boards found)');
      } else {
        for (final board in boards) {
          _log.info('  - ${board.toString()}');
        }
      }
      
      // Saved Artefacts
      final savedArtefacts = await SavedArtefactRepository().getAll();
      _log.info('\n💾 Saved Artefacts (${savedArtefacts.length}):');
      if (savedArtefacts.isEmpty) {
        _log.info('  (No saved artefacts found)');
      } else {
        for (final saved in savedArtefacts) {
          _log.info('  - ${saved.toString()}');
        }
      }
      
      // Sessions
      final sessions = await SessionMetaRepository().getAll();
      _log.info('\n🔄 Sessions (${sessions.length}):');
      if (sessions.isEmpty) {
        _log.info('  (No sessions found)');
      } else {
        for (final session in sessions) {
          _log.info('  - ${session.toString()}');
        }
      }
      
      _log.info('\n=== END ===\n');
    } catch (e) {
      _log.info('❌ Error reading database: $e');
    }
  }
  
  /// Gets the absolute path to the database file.
  static Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'vta.db');
  }
  
  /// Prints the database file path.
  static Future<void> printDatabasePath() async {
    try {
      final path = await getDatabasePath();
      _log.info(' Database location: $path');
    } catch (e) {
      _log.info('Error getting database path: $e');
    }
  }
  
  /// Gets database statistics.
  static Future<Map<String, int>> getDatabaseStats() async {
    return {
      'users': (await UserRepository().getAll()).length,
      'categories': (await CategoryRepository().getAll()).length,
      'artefacts': (await ArtefactRepository().getAll()).length,
      'boards': (await SavedBoardRepository().getAll()).length,
      'savedArtefacts': (await SavedArtefactRepository().getAll()).length,
      'sessions': (await SessionMetaRepository().getAll()).length,
    };
  }
  
  /// Prints database statistics.
  static Future<void> printDatabaseStats() async {
    _log.info('\n=== DATABASE STATISTICS ===\n');
    try {
      final stats = await getDatabaseStats();
      stats.forEach((table, count) {
        _log.info('  $table: $count records');
      });
      _log.info('\n=== END ===\n');
    } catch (e) {
      _log.info('Error getting stats: $e');
    }
  }
  
  /// Deletes all data from all tables (use with caution!).
  static Future<void> clearAllData() async {
    _log.info('Clearing all database data...');
    try {
      await UserRepository().deleteAll();
      await CategoryRepository().deleteAll();
      await ArtefactRepository().deleteAll();
      await SavedBoardRepository().deleteAll();
      await SavedArtefactRepository().deleteAll();
      await SessionMetaRepository().deleteAll();
      _log.info('All data cleared successfully');
    } catch (e) {
      _log.info('Error clearing data: $e');
    }
  }
  
  /// Deletes the entire database file (use with caution!).
  static Future<void> deleteDatabase() async {
    _log.info('Deleting database file...');
    try {
      await DatabaseHelper.instance.deleteDatabase();
      _log.info('Database deleted successfully');
    } catch (e) {
      _log.info('Error deleting database: $e');
    }
  }
  
  /// Creates sample test data for development.
  static Future<void> createSampleData() async {
    _log.info('Creating sample data...');
    
    try {
      // Create sample user
      final user = UserDB(
        id: 'user-test-001',
        name: 'Test User',
        username: 'testuser',
        nameVisible: 1,
        fieldCount: 5,
        modifiedDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await UserRepository().insert(user);
      
      // Create sample category
      final category = CategoryDB(
        categoryId: 'cat-test-001',
        userId: 'user-test-001',
        name: 'Test Category',
        categoryIndex: 0,
        usageCount: 0,
        modifiedDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await CategoryRepository().insert(category);
      
      // Create sample artefact
      final artefact = ArtefactDB(
        artefactId: 'art-test-001',
        artefactIndex: 0,
        userId: 'user-test-001',
        categoryId: 'cat-test-001',
        name: 'Test Artefact',
        nameShown: 1,
        modifiedDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await ArtefactRepository().insert(artefact);
      
      _log.info('Sample data created successfully');
      await printDatabaseStats();
    } catch (e) {
      _log.info('Error creating sample data: $e');
    }
  }
}
