
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


final _log = Logger('SyncUploader');

/// Result of an upload pass for a single entity type.
class UploadResult {
  final EntitySyncStats stats;
  final List<SyncError> errors;

  UploadResult({
    required this.stats,
    List<SyncError>? errors,
  }) : errors = errors ?? [];
}

/// Uploads locally-created or locally-modified entities to the backend.
///
/// Each `uploadLocal*` method accepts a list of already-synced IDs (from
/// [SyncDownloader]) so that only truly missing entities are pushed.
/// HTTP calls are wrapped in [RetryHelper] for transient-failure resilience.
class SyncUploader {
  final ApiProvider _apiProvider;
  final Token _token;
  final UserInfo _userInfo;
  final ArtefactRepository _artefactRepo;
  final SavedBoardRepository _boardRepo;
  final CategoryRepository _categoryRepo;

  SyncUploader({
    ApiProvider? apiProvider,
    Token? token,
    UserInfo? userInfo,
    ArtefactRepository? artefactRepo,
    SavedBoardRepository? boardRepo,
    CategoryRepository? categoryRepo,
  })  : _apiProvider = apiProvider ?? GetIt.instance.get<ApiProvider>(),
        _token = token ?? GetIt.instance.get<Token>(),
        _userInfo = userInfo ?? GetIt.instance.get<UserInfo>(),
        _artefactRepo = artefactRepo ?? ArtefactRepository(),
        _boardRepo = boardRepo ?? SavedBoardRepository(),
        _categoryRepo = categoryRepo ?? CategoryRepository();

  // ── Batch upload (missing-only) ───────────────────────────────

  /// Upload local artefacts that don't exist on backend.
  Future<UploadResult> uploadLocalArtefacts(List<String> syncedIds) async {
    final stats = EntitySyncStats(entityType: 'artefact');
    final List<SyncError> errors = [];
    try {
      final userId = _userInfo.userId;
      if (userId == null) {
        return UploadResult(stats: stats, errors: errors);
      }

      final localArtefacts = await _artefactRepo.getByUserId(userId);
      for (final artefact in localArtefacts) {
        if (syncedIds.contains(artefact.artefactId)) {
          stats.skipped++;
          continue;
        }
        try {
          final backendId = await _uploadArtefact(artefact);
          if (backendId != null) {
            syncedIds.add(backendId);
            stats.succeeded++;
          } else {
            stats.failed++;
            errors.add(SyncError(
              entityType: 'artefact',
              entityId: artefact.artefactId,
              message: 'Upload returned null ID',
            ));
          }
        } catch (e) {
          stats.failed++;
          errors.add(SyncError(
            entityType: 'artefact',
            entityId: artefact.artefactId,
            message: e.toString(),
          ));
        }
      }
    } catch (e) {
      _log.warning('[SYNC] ERROR uploading local artefacts: $e');
      errors.add(SyncError(entityType: 'artefact', message: e.toString()));
    }
    return UploadResult(stats: stats, errors: errors);
  }

  /// Upload local categories that don't exist on backend.
  Future<UploadResult> uploadLocalCategories(List<String> syncedIds) async {
    final stats = EntitySyncStats(entityType: 'category');
    final List<SyncError> errors = [];
    try {
      final userId = _userInfo.userId;
      if (userId == null) {
        return UploadResult(stats: stats, errors: errors);
      }

      final localCategories = await _categoryRepo.getByUserId(userId);
      for (final category in localCategories) {
        if (syncedIds.contains(category.categoryId)) {
          stats.skipped++;
          continue;
        }
        try {
          final success = await _uploadCategory(category);
          if (success) {
            stats.succeeded++;
          } else {
            stats.failed++;
            errors.add(SyncError(
              entityType: 'category',
              entityId: category.categoryId,
              message: 'Upload failed',
            ));
          }
        } catch (e) {
          stats.failed++;
          errors.add(SyncError(
            entityType: 'category',
            entityId: category.categoryId,
            message: e.toString(),
          ));
        }
      }
    } catch (e) {
      _log.warning('[SYNC] ERROR uploading local categories: $e');
      errors.add(SyncError(entityType: 'category', message: e.toString()));
    }
    return UploadResult(stats: stats, errors: errors);
  }

  /// Upload local boards that don't exist on backend.
  Future<UploadResult> uploadLocalBoards(List<String> syncedIds) async {
    final stats = EntitySyncStats(entityType: 'board');
    final List<SyncError> errors = [];
    try {
      final userId = _userInfo.userId;
      if (userId == null) {
        return UploadResult(stats: stats, errors: errors);
      }

      final localBoards = await _boardRepo.getByUserId(userId);
      for (final board in localBoards) {
        if (syncedIds.contains(board.id)) {
          stats.skipped++;
          continue;
        }
        try {
          final success = await _uploadBoard(board);
          if (success) {
            stats.succeeded++;
          } else {
            stats.failed++;
            errors.add(SyncError(
              entityType: 'board',
              entityId: board.id,
              message: 'Upload failed',
            ));
          }
        } catch (e) {
          stats.failed++;
          errors.add(SyncError(
            entityType: 'board',
            entityId: board.id,
            message: e.toString(),
          ));
        }
      }
    } catch (e) {
      _log.warning('[SYNC] ERROR uploading local boards: $e');
      errors.add(SyncError(entityType: 'board', message: e.toString()));
    }
    return UploadResult(stats: stats, errors: errors);
  }

  // ── Single-entity uploads ─────────────────────────────────────

  Future<String?> _uploadArtefact(ArtefactDB artefact) async {
    final uri = Uri.parse('${_apiProvider.baseUrl}Artefacts');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${_token.value}';

    request.fields['UserId'] = _userInfo.userId ?? '';
    request.fields['ArtefactId'] = artefact.artefactId;
    request.fields['Name'] = artefact.name ?? '';
    request.fields['NameShown'] = (artefact.nameShown == 1).toString();
    if (artefact.categoryId != null) {
      request.fields['CategoryId'] = artefact.categoryId!;
    }

    if (artefact.imagePath != null) {
      final imageFile = await _getLocalFile(
          'Artefacts', artefact.imagePath!, _userInfo.userId ?? '');
      if (imageFile != null && await imageFile.exists()) {
        request.files
            .add(await http.MultipartFile.fromPath('Image', imageFile.path));
      }
    }

    if (artefact.soundPath != null) {
      final soundFile = await _getLocalFile(
          'Sounds', artefact.soundPath!, _userInfo.userId ?? '');
      if (soundFile != null && await soundFile.exists()) {
        request.files
            .add(await http.MultipartFile.fromPath('Sound', soundFile.path));
      }
    }

    final result = await RetryHelper.run(
      () async {
        // Clone the request for each attempt (streams can only be read once)
        final cloned = http.MultipartRequest('POST', uri);
        cloned.headers.addAll(request.headers);
        cloned.fields.addAll(request.fields);
        for (final file in request.files) {
          cloned.files.add(await http.MultipartFile.fromPath(
            file.field,
            file.filename!,
          ));
        }
        return await cloned.send();
      },
      label: 'POST artefact ${artefact.artefactId}',
    );

    if (!result.succeeded) {
      _log.warning(
          '[SYNC] Failed to upload artefact ${artefact.artefactId} after retries');
      return null;
    }

    final streamedResponse = result.value!;
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      try {
        final responseData = json.decode(responseBody);
        return responseData['artefactId'] as String?;
      } catch (e) {
        _log.info(
            '[SYNC] Could not parse artefact ID from response: $e');
      }
    } else {
      _log.info(
          '[SYNC] Failed to upload artefact ${artefact.artefactId}: ${streamedResponse.statusCode}');
    }
    return null;
  }

  /// Returns `true` on success.
  Future<bool> _uploadCategory(CategoryDB category) async {
    final uri = Uri.parse('${_apiProvider.baseUrl}Categories');

    // Build the base request
    final baseFields = <String, String>{
      'UserId': _userInfo.userId ?? '',
      'CategoryId': category.categoryId,
      'Name': category.name ?? '',
    };

    File? imageFile;
    if (category.imagePath != null) {
      imageFile = await _getLocalFile(
          'Categories', category.imagePath!, _userInfo.userId ?? '');
      if (imageFile != null && !await imageFile.exists()) imageFile = null;
    }

    final result = await RetryHelper.run(
      () async {
        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer ${_token.value}';
        request.fields.addAll(baseFields);
        if (imageFile != null) {
          request.files.add(
              await http.MultipartFile.fromPath('Image', imageFile.path));
        }
        return await request.send();
      },
      label: 'POST category ${category.categoryId}',
    );

    if (!result.succeeded) {
      _log.warning(
          '[SYNC] Failed to upload category ${category.categoryId} after retries');
      return false;
    }

    final response = result.value!;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    final responseBody = await response.stream.bytesToString();
    _log.info(
        '[SYNC] Failed to upload category ${category.categoryId}: ${response.statusCode}');
    _log.fine('[SYNC] Response: $responseBody');
    return false;
  }

  /// Returns `true` on success.
  Future<bool> _uploadBoard(SavedBoardDB board) async {
    final result = await RetryHelper.runHttp(
      () => _apiProvider.postAsJson(
        'Boards',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
          'Content-Type': 'application/json',
        },
        body: {
          'userId': _userInfo.userId ?? '',
          'boardId': board.id,
          'name': board.name,
          'artefactIds': board.artefactIds?.split(',') ?? [],
          'savedArtefactIds': board.savedArtefactIds?.split(',') ?? [],
        },
      ),
      label: 'POST board ${board.id}',
    );

    final response = result.value;
    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      return true;
    }

    _log.info(
        '[SYNC] Failed to upload board ${board.id}: ${response?.statusCode}');
    return false;
  }

  // ── Helpers ───────────────────────────────────────────────────

  Future<File?> _getLocalFile(
      String assetType, String filename, String userId) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      return File('${appDir.path}/Synced/$assetType/$userId/$filename');
    } catch (e) {
      return null;
    }
  }
}
