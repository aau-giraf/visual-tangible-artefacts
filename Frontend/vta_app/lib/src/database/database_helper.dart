import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database helper class for managing SQLite database operations.
/// Implements singleton pattern to ensure single database instance.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Gets the database instance, creating it if it doesn't exist.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vta.db');
    return _database!;
  }

  /// Initializes the database at the specified file path.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates all database tables with the schema from SQLite_schema.sql
  Future<void> _createDB(Database db, int version) async {
    // Create user table
    await db.execute('''
      CREATE TABLE user (
        id TEXT PRIMARY KEY,
        name TEXT,
        username TEXT,
        name_visible INTEGER NOT NULL,
        field_count INTEGER NOT NULL,
        modified_date INTEGER,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create category table
    await db.execute('''
      CREATE TABLE category (
        category_id TEXT PRIMARY KEY,
        category_index INTEGER,
        user_id TEXT NOT NULL,
        name TEXT,
        image_path TEXT,
        modified_date INTEGER,
        usage_count INTEGER NOT NULL DEFAULT 0,
        last_used_date INTEGER,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create artefact table
    await db.execute('''
      CREATE TABLE artefact (
        artefact_id TEXT PRIMARY KEY,
        artefact_index INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        category_id TEXT,
        image_path TEXT,
        sound_path TEXT,
        modified_date INTEGER,
        name TEXT,
        name_shown INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create saved_board table
    await db.execute('''
      CREATE TABLE saved_board (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        saved_artefact_ids TEXT,
        artefact_ids TEXT,
        snapshot_path TEXT,
        created_date INTEGER NOT NULL,
        modified_date INTEGER,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create saved_artefact table
    await db.execute('''
      CREATE TABLE saved_artefact (
        id TEXT PRIMARY KEY,
        artefact_id TEXT NOT NULL,
        board_id TEXT NOT NULL,
        pos_x REAL NOT NULL DEFAULT 0,
        pos_y REAL NOT NULL DEFAULT 0,
        width REAL NOT NULL DEFAULT 200,
        height REAL NOT NULL DEFAULT 200,
        created_date INTEGER NOT NULL,
        modified_date INTEGER,
        name_visible INTEGER,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create session_meta table
    await db.execute('''
      CREATE TABLE session_meta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        board_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        last_synced_at INTEGER,
        is_dirty INTEGER NOT NULL
      )
    ''');

    // Create sync_metadata table for tracking sync operations
    await db.execute('''
      CREATE TABLE sync_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        last_sync_date INTEGER NOT NULL,
        last_check_date INTEGER NOT NULL,
        UNIQUE(user_id, entity_type)
      )
    ''');
  }

  /// Handles database schema upgrades.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add sync_metadata table for version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_metadata (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          entity_type TEXT NOT NULL,
          last_sync_date INTEGER NOT NULL,
          last_check_date INTEGER NOT NULL,
          UNIQUE(user_id, entity_type)
        )
      ''');
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  /// Deletes the database file (useful for testing or reset).
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vta.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
