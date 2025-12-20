// ignore_for_file: avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database.dart';

/// Debug helper class for viewing and managing SQLite database during development.
class DatabaseDebugHelper {
  /// Prints all data from all tables in the database.
  static Future<void> printAllData() async {
    print('\n=== 📊 DATABASE CONTENTS ===\n');
    
    try {
      // Users
      final users = await UserRepository().getAll();
      print('👥 Users (${users.length}):');
      if (users.isEmpty) {
        print('  (No users found)');
      } else {
        for (final user in users) {
          print('  - ${user.toString()}');
        }
      }
      
      // Categories
      final categories = await CategoryRepository().getAll();
      print('\n📁 Categories (${categories.length}):');
      if (categories.isEmpty) {
        print('  (No categories found)');
      } else {
        for (final category in categories) {
          print('  - ${category.toString()}');
        }
      }
      
      // Artefacts
      final artefacts = await ArtefactRepository().getAll();
      print('\n🎨 Artefacts (${artefacts.length}):');
      if (artefacts.isEmpty) {
        print('  (No artefacts found)');
      } else {
        for (final artefact in artefacts) {
          print('  - ${artefact.toString()}');
        }
      }
      
      // Boards
      final boards = await SavedBoardRepository().getAll();
      print('\n📋 Boards (${boards.length}):');
      if (boards.isEmpty) {
        print('  (No boards found)');
      } else {
        for (final board in boards) {
          print('  - ${board.toString()}');
        }
      }
      
      // Saved Artefacts
      final savedArtefacts = await SavedArtefactRepository().getAll();
      print('\n💾 Saved Artefacts (${savedArtefacts.length}):');
      if (savedArtefacts.isEmpty) {
        print('  (No saved artefacts found)');
      } else {
        for (final saved in savedArtefacts) {
          print('  - ${saved.toString()}');
        }
      }
      
      // Sessions
      final sessions = await SessionMetaRepository().getAll();
      print('\n🔄 Sessions (${sessions.length}):');
      if (sessions.isEmpty) {
        print('  (No sessions found)');
      } else {
        for (final session in sessions) {
          print('  - ${session.toString()}');
        }
      }
      
      print('\n=== END ===\n');
    } catch (e) {
      print('❌ Error reading database: $e');
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
      print(' Database location: $path');
    } catch (e) {
      print('Error getting database path: $e');
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
    print('\n=== DATABASE STATISTICS ===\n');
    try {
      final stats = await getDatabaseStats();
      stats.forEach((table, count) {
        print('  $table: $count records');
      });
      print('\n=== END ===\n');
    } catch (e) {
      print('Error getting stats: $e');
    }
  }
  
  /// Deletes all data from all tables (use with caution!).
  static Future<void> clearAllData() async {
    print('Clearing all database data...');
    try {
      await UserRepository().deleteAll();
      await CategoryRepository().deleteAll();
      await ArtefactRepository().deleteAll();
      await SavedBoardRepository().deleteAll();
      await SavedArtefactRepository().deleteAll();
      await SessionMetaRepository().deleteAll();
      print('All data cleared successfully');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
  
  /// Deletes the entire database file (use with caution!).
  static Future<void> deleteDatabase() async {
    print('Deleting database file...');
    try {
      await DatabaseHelper.instance.deleteDatabase();
      print('Database deleted successfully');
    } catch (e) {
      print('Error deleting database: $e');
    }
  }
  
  /// Creates sample test data for development.
  static Future<void> createSampleData() async {
    print('Creating sample data...');
    
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
      
      print('Sample data created successfully');
      await printDatabaseStats();
    } catch (e) {
      print('Error creating sample data: $e');
    }
  }
}
