
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


final _log = Logger('SyncUploader');
/// Uploads locally-created or locally-modified entities to the backend.
///
/// Each `uploadLocal*` method accepts a list of already-synced IDs (from
/// [SyncDownloader]) so that only truly missing entities are pushed.
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
  Future<void> uploadLocalArtefacts(List<String> syncedIds) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return;

      final localArtefacts = await _artefactRepo.getByUserId(userId);
      for (final artefact in localArtefacts) {
        if (syncedIds.contains(artefact.artefactId)) continue;
        final backendId = await _uploadArtefact(artefact);
        if (backendId != null) syncedIds.add(backendId);
      }
    } catch (e) {
      _log.info('[SYNC] ERROR uploading local artefacts: $e');
    }
  }

  /// Upload local categories that don't exist on backend.
  Future<void> uploadLocalCategories(List<String> syncedIds) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return;

      final localCategories = await _categoryRepo.getByUserId(userId);
      for (final category in localCategories) {
        if (syncedIds.contains(category.categoryId)) continue;
        await _uploadCategory(category);
      }
    } catch (e) {
      _log.info('[SYNC] ERROR uploading local categories: $e');
    }
  }

  /// Upload local boards that don't exist on backend.
  Future<void> uploadLocalBoards(List<String> syncedIds) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return;

      final localBoards = await _boardRepo.getByUserId(userId);
      for (final board in localBoards) {
        if (syncedIds.contains(board.id)) continue;
        await _uploadBoard(board);
      }
    } catch (e) {
      _log.info('[SYNC] ERROR uploading local boards: $e');
    }
  }

  // ── Single-entity uploads ─────────────────────────────────────

  Future<String?> _uploadArtefact(ArtefactDB artefact) async {
    try {
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

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(responseBody);
          return responseData['artefactId'] as String?;
        } catch (e) {
          _log.info(
              '[SYNC] ERROR: Could not parse artefact ID from response: $e');
        }
      } else {
        _log.info(
            '[SYNC] ERROR: Failed to upload artefact ${artefact.artefactId}: ${response.statusCode}');
        _log.info('[SYNC] Response: $responseBody');
      }
      return null;
    } catch (e, stackTrace) {
      _log.info('[SYNC] ERROR uploading artefact: $e');
      _log.info('[SYNC] Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _uploadCategory(CategoryDB category) async {
    try {
      final uri = Uri.parse('${_apiProvider.baseUrl}Categories');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${_token.value}';

      request.fields['UserId'] = _userInfo.userId ?? '';
      request.fields['CategoryId'] = category.categoryId;
      request.fields['Name'] = category.name ?? '';

      if (category.imagePath != null) {
        final imageFile = await _getLocalFile(
            'Categories', category.imagePath!, _userInfo.userId ?? '');
        if (imageFile != null && await imageFile.exists()) {
          request.files
              .add(await http.MultipartFile.fromPath('Image', imageFile.path));
        }
      }

      final response = await request.send();
      if (response.statusCode != 200 && response.statusCode != 201) {
        final responseBody = await response.stream.bytesToString();
        _log.info(
            '[SYNC] ERROR: Failed to upload category ${category.categoryId}: ${response.statusCode}');
        _log.info('[SYNC] Response: $responseBody');
      }
    } catch (e) {
      _log.info('[SYNC] ERROR uploading category: $e');
    }
  }

  Future<void> _uploadBoard(SavedBoardDB board) async {
    try {
      final response = await _apiProvider.postAsJson(
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
      );

      if (response == null ||
          (response.statusCode != 200 && response.statusCode != 201)) {
        _log.info(
            '[SYNC] ERROR: Failed to upload board ${board.id}: ${response?.statusCode}');
      }
    } catch (e) {
      _log.info('[SYNC] ERROR uploading board: $e');
    }
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
