
import 'dart:convert';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/utilities/retry_helper.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/database/database.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:vta_app/src/services/sync_models.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';


final _log = Logger('SyncDownloader');
/// Result of a download pass for a single entity type.
class DownloadResult {
  final List<String> syncedIds;
  final EntitySyncStats stats;
  final List<SyncError> errors;

  DownloadResult({
    required this.syncedIds,
    required this.stats,
    List<SyncError>? errors,
  }) : errors = errors ?? [];
}

/// Downloads entities from the backend and persists them in the local SQLite DB.
///
/// Each `download*` method handles one entity type. Assets (images, sounds) are
/// downloaded to the app-support directory. HTTP calls are wrapped in
/// [RetryHelper] for transient-failure resilience, and DB writes are batched
/// inside SQLite transactions.
class SyncDownloader {
  final ApiProvider _apiProvider;
  final Token _token;
  final UserInfo _userInfo;
  final ArtefactRepository _artefactRepo;
  final SavedBoardRepository _boardRepo;
  final CategoryRepository _categoryRepo;
  final SavedArtefactRepository _savedArtefactRepo;
  final DatabaseHelper _dbHelper;

  SyncDownloader({
    ApiProvider? apiProvider,
    Token? token,
    UserInfo? userInfo,
    ArtefactRepository? artefactRepo,
    SavedBoardRepository? boardRepo,
    CategoryRepository? categoryRepo,
    SavedArtefactRepository? savedArtefactRepo,
    DatabaseHelper? dbHelper,
  })  : _apiProvider = apiProvider ?? GetIt.instance.get<ApiProvider>(),
        _token = token ?? GetIt.instance.get<Token>(),
        _userInfo = userInfo ?? GetIt.instance.get<UserInfo>(),
        _artefactRepo = artefactRepo ?? ArtefactRepository(),
        _boardRepo = boardRepo ?? SavedBoardRepository(),
        _categoryRepo = categoryRepo ?? CategoryRepository(),
        _savedArtefactRepo = savedArtefactRepo ?? SavedArtefactRepository(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ── Public download orchestrators ─────────────────────────────

  /// Download all artefacts from the backend.
  ///
  /// Returns a [DownloadResult] containing the list of synced IDs (for the
  /// upload-missing step) plus per-entity stats and any errors.
  Future<DownloadResult> downloadArtefacts() async {
    final stats = EntitySyncStats(entityType: 'artefact');
    final List<SyncError> errors = [];
    final List<String> syncedIds = [];

    try {
      final result = await RetryHelper.runHttp(
        () => _apiProvider.fetchAsJson(
          'Artefacts',
          headers: {'Authorization': 'Bearer ${_token.value}'},
        ),
        label: 'GET Artefacts',
      );

      final response = result.value;
      if (response != null && response.statusCode == 200) {
        final List<dynamic> artefactsData = json.decode(response.body);

        // Download assets before the transaction (network I/O)
        final assetPaths = <String, _AssetPaths>{};
        for (final data in artefactsData) {
          final artefactId = data['artefactId'] as String?;
          if (artefactId == null) continue;
          assetPaths[artefactId] = await _downloadArtefactAssets(data);
        }

        // Batch DB writes inside a transaction
        final db = await _dbHelper.database;
        await db.transaction((txn) async {
          for (final data in artefactsData) {
            try {
              final artefactId = data['artefactId'] as String?;
              if (artefactId == null) {
                stats.skipped++;
                continue;
              }
              final wrote = await _syncArtefact(
                  data, txn, assetPaths[artefactId] ?? _AssetPaths());
              if (wrote) {
                stats.succeeded++;
              } else {
                stats.skipped++;
              }
              syncedIds.add(artefactId);
            } catch (e) {
              stats.failed++;
              errors.add(SyncError(
                entityType: 'artefact',
                entityId: data['artefactId'] as String?,
                message: e.toString(),
              ));
              _log.warning('[SYNC] ERROR syncing artefact: $e');
            }
          }
        });
      } else {
        errors.add(SyncError(
          entityType: 'artefact',
          message: 'HTTP ${response?.statusCode ?? "null"} fetching artefacts',
        ));
      }
    } catch (e) {
      _log.warning('[SYNC] ERROR downloading artefacts: $e');
      errors.add(SyncError(entityType: 'artefact', message: e.toString()));
    }
    return DownloadResult(syncedIds: syncedIds, stats: stats, errors: errors);
  }

  /// Download all categories from the backend.
  Future<DownloadResult> downloadCategories() async {
    final stats = EntitySyncStats(entityType: 'category');
    final List<SyncError> errors = [];
    final List<String> syncedIds = [];

    try {
      final result = await RetryHelper.runHttp(
        () => _apiProvider.fetchAsJson(
          'Categories',
          headers: {'Authorization': 'Bearer ${_token.value}'},
        ),
        label: 'GET Categories',
      );

      final response = result.value;
      if (response != null && response.statusCode == 200) {
        final List<dynamic> categoriesData = json.decode(response.body);

        // Download assets before the transaction (network I/O)
        final assetPaths = <String, String?>{};
        for (final data in categoriesData) {
          final categoryId = data['categoryId'] as String?;
          if (categoryId == null) continue;
          final imageUrl = data['imageUrl'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            assetPaths[categoryId] = await _downloadAsset(
              imageUrl,
              'Categories',
              'image_$categoryId',
              _userInfo.userId ?? '',
            );
          }
        }

        // Batch DB writes inside a transaction
        final db = await _dbHelper.database;
        await db.transaction((txn) async {
          for (final data in categoriesData) {
            try {
              final categoryId = data['categoryId'] as String?;
              if (categoryId == null) {
                stats.skipped++;
                continue;
              }
              final wrote = await _syncCategory(
                  data, txn, assetPaths[categoryId]);
              if (wrote) {
                stats.succeeded++;
              } else {
                stats.skipped++;
              }
              syncedIds.add(categoryId);
            } catch (e) {
              stats.failed++;
              errors.add(SyncError(
                entityType: 'category',
                entityId: data['categoryId'] as String?,
                message: e.toString(),
              ));
              _log.warning('[SYNC] ERROR syncing category: $e');
            }
          }
        });
      } else {
        errors.add(SyncError(
          entityType: 'category',
          message:
              'HTTP ${response?.statusCode ?? "null"} fetching categories',
        ));
      }
    } catch (e) {
      _log.warning('[SYNC] ERROR downloading categories: $e');
      errors.add(SyncError(entityType: 'category', message: e.toString()));
    }
    return DownloadResult(syncedIds: syncedIds, stats: stats, errors: errors);
  }

  /// Download all boards (with their saved artefacts) from the backend.
  Future<DownloadResult> downloadBoards() async {
    final stats = EntitySyncStats(entityType: 'board');
    final List<SyncError> errors = [];
    final List<String> syncedIds = [];

    try {
      final result = await RetryHelper.runHttp(
        () => _apiProvider.fetchAsJson(
          'Boards',
          headers: {'Authorization': 'Bearer ${_token.value}'},
        ),
        label: 'GET Boards',
      );

      final response = result.value;
      if (response != null && response.statusCode == 200) {
        final List<dynamic> boardsData = json.decode(response.body);

        // Batch DB writes inside a transaction
        final db = await _dbHelper.database;
        await db.transaction((txn) async {
          for (final data in boardsData) {
            try {
              final boardId =
                  data['boardId'] as String? ?? data['id'] as String?;
              if (boardId == null) {
                stats.skipped++;
                continue;
              }
              final wrote = await _syncBoard(data, txn);
              if (wrote) {
                stats.succeeded++;
              } else {
                stats.skipped++;
              }
              syncedIds.add(boardId);
            } catch (e) {
              stats.failed++;
              final boardId =
                  data['boardId'] as String? ?? data['id'] as String?;
              errors.add(SyncError(
                entityType: 'board',
                entityId: boardId,
                message: e.toString(),
              ));
              _log.warning('[SYNC] ERROR syncing board: $e');
            }
          }
        });
      } else {
        errors.add(SyncError(
          entityType: 'board',
          message: 'HTTP ${response?.statusCode ?? "null"} fetching boards',
        ));
      }
    } catch (e) {
      _log.warning('[SYNC] ERROR downloading boards: $e');
      errors.add(SyncError(entityType: 'board', message: e.toString()));
    }
    return DownloadResult(syncedIds: syncedIds, stats: stats, errors: errors);
  }

  // ── Private per-entity sync ───────────────────────────────────

  /// Pre-downloaded asset paths for an artefact.
  Future<_AssetPaths> _downloadArtefactAssets(
      Map<String, dynamic> data) async {
    String? localImagePath;
    String? localSoundPath;

    final imageUrl = data['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      localImagePath = await _downloadAsset(
        imageUrl,
        'Artefacts',
        'image_${data['artefactId']}',
        _userInfo.userId ?? '',
      );
    }

    final soundUrl = data['soundUrl'] as String?;
    if (soundUrl != null && soundUrl.isNotEmpty) {
      localSoundPath = await _downloadAsset(
        soundUrl,
        'Sounds',
        'sound_${data['artefactId']}',
        _userInfo.userId ?? '',
      );
    }

    return _AssetPaths(imagePath: localImagePath, soundPath: localSoundPath);
  }

  /// Returns `true` if the entity was written, `false` if skipped.
  Future<bool> _syncArtefact(
    Map<String, dynamic> data,
    Transaction txn,
    _AssetPaths assets,
  ) async {
    final artefactId = data['artefactId'] as String?;
    if (artefactId == null) return false;

    final existing = await _artefactRepo.getById(artefactId);

    final backendModifiedDate = _parseDate(data['modifiedDate'] as String?);
    final syncDirection =
        _decideSyncDirection(existing?.modifiedDate, backendModifiedDate);

    if (syncDirection != 'download') return false;

    final imageUrl = data['imageUrl'] as String?;
    final soundUrl = data['soundUrl'] as String?;

    final artefact = ArtefactDB(
      artefactId: artefactId,
      artefactIndex: data['artefactIndex'] as int? ?? 0,
      userId: data['userId'] as String? ?? _userInfo.userId ?? '',
      categoryId: data['categoryId'] as String?,
      imagePath: assets.imagePath ?? _extractFilename(imageUrl),
      soundPath: assets.soundPath ?? _extractFilename(soundUrl),
      modifiedDate: _parseDate(data['modifiedDate'] as String?),
      name: data['name'] as String?,
      nameShown: (data['nameShown'] as bool?) == true ? 1 : 0,
      isDeleted: (data['isDeleted'] as bool?) == true ? 1 : 0,
    );

    if (existing != null) {
      await txn.update(
        'artefact',
        artefact.toMap(),
        where: 'artefact_id = ?',
        whereArgs: [artefact.artefactId],
      );
    } else {
      await txn.insert(
        'artefact',
        artefact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return true;
  }

  /// Returns `true` if the entity was written, `false` if skipped.
  Future<bool> _syncCategory(
    Map<String, dynamic> data,
    Transaction txn,
    String? localImagePath,
  ) async {
    final categoryId = data['categoryId'] as String?;
    if (categoryId == null) return false;

    final existing = await _categoryRepo.getById(categoryId);

    final backendModifiedDate = _parseDate(data['modifiedDate'] as String?);
    final syncDirection =
        _decideSyncDirection(existing?.modifiedDate, backendModifiedDate);

    if (syncDirection != 'download') return false;

    final imageUrl = data['imageUrl'] as String?;

    final category = CategoryDB(
      categoryId: categoryId,
      categoryIndex: data['categoryIndex'] as int?,
      userId: data['userId'] as String? ?? _userInfo.userId ?? '',
      name: data['name'] as String?,
      imagePath: localImagePath ?? _extractFilename(imageUrl),
      modifiedDate: _parseDate(data['modifiedDate'] as String?),
      usageCount: data['usageCount'] as int? ?? 0,
      lastUsedDate: _parseDate(data['lastUsedDate'] as String?),
      isDeleted: (data['isDeleted'] as bool?) == true ? 1 : 0,
    );

    if (existing != null) {
      await txn.update(
        'category',
        category.toMap(),
        where: 'category_id = ?',
        whereArgs: [category.categoryId],
      );
    } else {
      await txn.insert(
        'category',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return true;
  }

  /// Returns `true` if the entity was written, `false` if skipped.
  Future<bool> _syncBoard(Map<String, dynamic> data, Transaction txn) async {
    final boardId = data['boardId'] as String? ?? data['id'] as String?;
    if (boardId == null) return false;

    final existing = await _boardRepo.getById(boardId);

    final backendModifiedDate = _parseDate(data['modifiedDate'] as String?);
    final syncDirection =
        _decideSyncDirection(existing?.modifiedDate, backendModifiedDate);

    if (syncDirection != 'download') return false;

    final artefactIds = (data['artefactIds'] as List<dynamic>?)
        ?.map((id) => id.toString())
        .join(',');
    final savedArtefactIds = (data['savedArtefactIds'] as List<dynamic>?)
        ?.map((id) => id.toString())
        .join(',');

    final board = SavedBoardDB(
      id: boardId,
      name: data['name'] as String? ?? 'Unnamed Board',
      userId: data['userId'] as String? ?? _userInfo.userId ?? '',
      savedArtefactIds: savedArtefactIds,
      artefactIds: artefactIds,
      snapshotPath: _extractFilename(data['snapshotUrl'] as String?),
      createdDate: _parseDate(data['createdDate'] as String?) ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      modifiedDate: _parseDate(data['modifiedDate'] as String?),
      isDeleted: (data['isDeleted'] as bool?) == true ? 1 : 0,
    );

    if (existing != null) {
      await txn.update(
        'saved_board',
        board.toMap(),
        where: 'id = ?',
        whereArgs: [board.id],
      );
    } else {
      await txn.insert(
        'saved_board',
        board.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Sync saved artefacts for this board
    final savedArtefacts = data['savedArtefacts'] as List<dynamic>?;
    if (savedArtefacts != null) {
      for (final savedArtefactData in savedArtefacts) {
        await _syncSavedArtefact(savedArtefactData, boardId, txn);
      }
    }
    return true;
  }

  Future<void> _syncSavedArtefact(
      Map<String, dynamic> data, String boardId, Transaction txn) async {
    final id = data['id'] as String?;
    if (id == null) return;

    final savedArtefact = SavedArtefactDB(
      id: id,
      artefactId: data['artefactId'] as String? ?? '',
      boardId: boardId,
      posX: (data['posX'] as num?)?.toDouble() ?? 0.0,
      posY: (data['posY'] as num?)?.toDouble() ?? 0.0,
      width: (data['width'] as num?)?.toDouble() ?? 200.0,
      height: (data['height'] as num?)?.toDouble() ?? 200.0,
      createdDate: _parseDate(data['createdDate'] as String?) ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      modifiedDate: _parseDate(data['modifiedDate'] as String?),
      nameVisible: (data['nameVisible'] as bool?) == true ? 1 : null,
      isDeleted: (data['isDeleted'] as bool?) == true ? 1 : 0,
    );

    final existing = await _savedArtefactRepo.getById(id);
    if (existing != null) {
      await txn.update(
        'saved_artefact',
        savedArtefact.toMap(),
        where: 'id = ?',
        whereArgs: [savedArtefact.id],
      );
    } else {
      await txn.insert(
        'saved_artefact',
        savedArtefact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ── Shared helpers ────────────────────────────────────────────

  /// Compare timestamps to decide whether to download, upload, or skip.
  String _decideSyncDirection(
      int? localModifiedDate, int? backendModifiedDate) {
    if (localModifiedDate == null) return 'download';
    if (backendModifiedDate == null) return 'upload';
    if (backendModifiedDate > localModifiedDate) return 'download';
    if (localModifiedDate > backendModifiedDate) return 'upload';
    return 'skip';
  }

  /// Download an asset (image / sound) and write it to local storage.
  ///
  /// Uses [RetryHelper] for transient network failures.
  Future<String?> _downloadAsset(
    String url,
    String assetType,
    String filename,
    String userId,
  ) async {
    try {
      final fullUrl =
          url.startsWith('http') ? url : _apiProvider.baseUrl + url;

      final result = await RetryHelper.run(
        () => http.get(
          Uri.parse(fullUrl),
          headers: {'Authorization': 'Bearer ${_token.value}'},
        ),
        label: 'GET asset $filename',
      );

      if (!result.succeeded) {
        _log.info('[SYNC] Failed to download asset after retries: $fullUrl');
        return null;
      }

      final response = result.value!;
      if (response.statusCode != 200) {
        _log.info(
            '[SYNC] Failed to download asset: ${response.statusCode} - $fullUrl');
        return null;
      }

      final appDir = await getApplicationSupportDirectory();
      final assetDir = Directory('${appDir.path}/Synced/$assetType/$userId');
      if (!await assetDir.exists()) {
        await assetDir.create(recursive: true);
      }

      final file = File('${assetDir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);

      return filename;
    } catch (e) {
      _log.info('[SYNC] ERROR downloading asset from $url: $e');
      return null;
    }
  }

  /// Extract the last path segment from a URL.
  String? _extractFilename(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final segments = uri.pathSegments;
    return segments.isNotEmpty ? segments.last : url;
  }

  /// Parse an ISO 8601 date string to Unix seconds.
  int? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final dateTime = DateTime.parse(dateStr);
      return dateTime.millisecondsSinceEpoch ~/ 1000;
    } catch (e) {
      _log.info('[SYNC] Error parsing date: $dateStr - $e');
      return null;
    }
  }
}

/// Pre-downloaded asset paths for an artefact.
class _AssetPaths {
  final String? imagePath;
  final String? soundPath;
  _AssetPaths({this.imagePath, this.soundPath});
}
