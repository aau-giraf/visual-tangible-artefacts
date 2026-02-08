
import 'dart:convert';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/database/database.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:logging/logging.dart';


final _log = Logger('SyncDownloader');
/// Downloads entities from the backend and persists them in the local SQLite DB.
///
/// Each `sync*` method handles one entity type. Assets (images, sounds) are
/// downloaded to the app-support directory.
class SyncDownloader {
  final ApiProvider _apiProvider;
  final Token _token;
  final UserInfo _userInfo;
  final ArtefactRepository _artefactRepo;
  final SavedBoardRepository _boardRepo;
  final CategoryRepository _categoryRepo;
  final SavedArtefactRepository _savedArtefactRepo;

  SyncDownloader({
    ApiProvider? apiProvider,
    Token? token,
    UserInfo? userInfo,
    ArtefactRepository? artefactRepo,
    SavedBoardRepository? boardRepo,
    CategoryRepository? categoryRepo,
    SavedArtefactRepository? savedArtefactRepo,
  })  : _apiProvider = apiProvider ?? GetIt.instance.get<ApiProvider>(),
        _token = token ?? GetIt.instance.get<Token>(),
        _userInfo = userInfo ?? GetIt.instance.get<UserInfo>(),
        _artefactRepo = artefactRepo ?? ArtefactRepository(),
        _boardRepo = boardRepo ?? SavedBoardRepository(),
        _categoryRepo = categoryRepo ?? CategoryRepository(),
        _savedArtefactRepo = savedArtefactRepo ?? SavedArtefactRepository();

  // ── Public download orchestrators ─────────────────────────────

  /// Download all artefacts from the backend.
  ///
  /// Returns the list of artefact IDs that were synced so that the caller
  /// can pass them to [SyncUploader] for the upload-missing step.
  Future<List<String>> downloadArtefacts() async {
    final List<String> syncedIds = [];
    try {
      final response = await _apiProvider.fetchAsJson(
        'Artefacts',
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> artefactsData = json.decode(response.body);
        for (final data in artefactsData) {
          await _syncArtefact(data);
          syncedIds.add(data['artefactId'] as String);
        }
      }
    } catch (e) {
      _log.info('[SYNC] ERROR downloading artefacts: $e');
    }
    return syncedIds;
  }

  /// Download all categories from the backend.
  Future<List<String>> downloadCategories() async {
    final List<String> syncedIds = [];
    try {
      final response = await _apiProvider.fetchAsJson(
        'Categories',
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> categoriesData = json.decode(response.body);
        for (final data in categoriesData) {
          await _syncCategory(data);
          syncedIds.add(data['categoryId'] as String);
        }
      }
    } catch (e) {
      _log.info('[SYNC] ERROR downloading categories: $e');
    }
    return syncedIds;
  }

  /// Download all boards (with their saved artefacts) from the backend.
  Future<List<String>> downloadBoards() async {
    final List<String> syncedIds = [];
    try {
      final response = await _apiProvider.fetchAsJson(
        'Boards',
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> boardsData = json.decode(response.body);
        for (final data in boardsData) {
          await _syncBoard(data);
          syncedIds.add(data['boardId'] as String? ?? data['id'] as String);
        }
      }
    } catch (e) {
      _log.info('[SYNC] ERROR downloading boards: $e');
    }
    return syncedIds;
  }

  // ── Private per-entity sync ───────────────────────────────────

  Future<void> _syncArtefact(Map<String, dynamic> data) async {
    try {
      final artefactId = data['artefactId'] as String?;
      if (artefactId == null) return;

      final existing = await _artefactRepo.getById(artefactId);

      final backendModifiedDate = _parseDate(data['modifiedDate'] as String?);
      final syncDirection =
          _decideSyncDirection(existing?.modifiedDate, backendModifiedDate);

      if (syncDirection != 'download') return;

      // Download image and sound files if they have URLs
      String? localImagePath;
      String? localSoundPath;

      final imageUrl = data['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        localImagePath = await _downloadAsset(
          imageUrl,
          'Artefacts',
          'image_$artefactId',
          _userInfo.userId ?? '',
        );
      }

      final soundUrl = data['soundUrl'] as String?;
      if (soundUrl != null && soundUrl.isNotEmpty) {
        localSoundPath = await _downloadAsset(
          soundUrl,
          'Sounds',
          'sound_$artefactId',
          _userInfo.userId ?? '',
        );
      }

      final artefact = ArtefactDB(
        artefactId: artefactId,
        artefactIndex: data['artefactIndex'] as int? ?? 0,
        userId: data['userId'] as String? ?? _userInfo.userId ?? '',
        categoryId: data['categoryId'] as String?,
        imagePath: localImagePath ?? _extractFilename(imageUrl),
        soundPath: localSoundPath ?? _extractFilename(soundUrl),
        modifiedDate: _parseDate(data['modifiedDate'] as String?),
        name: data['name'] as String?,
        nameShown: (data['nameShown'] as bool?) == true ? 1 : 0,
        isDeleted: (data['isDeleted'] as bool?) == true ? 1 : 0,
      );

      if (existing != null) {
        await _artefactRepo.update(artefact);
      } else {
        await _artefactRepo.insert(artefact);
      }
    } catch (e) {
      _log.info('[SYNC] ERROR syncing artefact: $e');
    }
  }

  Future<void> _syncCategory(Map<String, dynamic> data) async {
    try {
      final categoryId = data['categoryId'] as String?;
      if (categoryId == null) return;

      final existing = await _categoryRepo.getById(categoryId);

      final backendModifiedDate = _parseDate(data['modifiedDate'] as String?);
      final syncDirection =
          _decideSyncDirection(existing?.modifiedDate, backendModifiedDate);

      if (syncDirection != 'download') return;

      String? localImagePath;
      final imageUrl = data['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        localImagePath = await _downloadAsset(
          imageUrl,
          'Categories',
          'image_$categoryId',
          _userInfo.userId ?? '',
        );
      }

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
        await _categoryRepo.update(category);
      } else {
        await _categoryRepo.insert(category);
      }
    } catch (e) {
      _log.info('[SYNC] ERROR syncing category: $e');
    }
  }

  Future<void> _syncBoard(Map<String, dynamic> data) async {
    try {
      final boardId = data['boardId'] as String? ?? data['id'] as String?;
      if (boardId == null) return;

      final existing = await _boardRepo.getById(boardId);

      final backendModifiedDate = _parseDate(data['modifiedDate'] as String?);
      final syncDirection =
          _decideSyncDirection(existing?.modifiedDate, backendModifiedDate);

      if (syncDirection != 'download') return;

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
        await _boardRepo.update(board);
      } else {
        await _boardRepo.insert(board);
      }

      // Sync saved artefacts for this board
      final savedArtefacts = data['savedArtefacts'] as List<dynamic>?;
      if (savedArtefacts != null) {
        for (final savedArtefactData in savedArtefacts) {
          await _syncSavedArtefact(savedArtefactData, boardId);
        }
      }
    } catch (e) {
      _log.info('[SYNC] ERROR syncing board: $e');
    }
  }

  Future<void> _syncSavedArtefact(
      Map<String, dynamic> data, String boardId) async {
    try {
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
        await _savedArtefactRepo.update(savedArtefact);
      } else {
        await _savedArtefactRepo.insert(savedArtefact);
      }
    } catch (e) {
      _log.info('[SYNC] ERROR syncing saved artefact: $e');
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
  Future<String?> _downloadAsset(
    String url,
    String assetType,
    String filename,
    String userId,
  ) async {
    try {
      final fullUrl =
          url.startsWith('http') ? url : _apiProvider.baseUrl + url;

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );

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
