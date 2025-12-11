import 'dart:convert';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/database/database.dart';
import 'package:vta_app/src/singletons/user_info.dart';

/// Model representing a file change record
class FileChangeRecord {
  final String fileId;
  final String fileName;
  final String fileType; // 'artefact' or 'board'
  final DateTime? modifiedDate;
  final String? imageUrl;
  final String? soundUrl;

  FileChangeRecord({
    required this.fileId,
    required this.fileName,
    required this.fileType,
    this.modifiedDate,
    this.imageUrl,
    this.soundUrl,
  });

  factory FileChangeRecord.fromJson(Map<String, dynamic> json) {
    return FileChangeRecord(
      fileId: json['fileId'] as String,
      fileName: json['fileName'] as String,
      fileType: json['fileType'] as String,
      modifiedDate: json['modifiedDate'] != null 
          ? DateTime.parse(json['modifiedDate'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      soundUrl: json['soundUrl'] as String?,
    );
  }

  factory FileChangeRecord.fromArtefact(Map<String, dynamic> json) {
    return FileChangeRecord(
      fileId: json['artefactId'] as String,
      fileName: json['name'] as String? ?? 'Unnamed Artefact',
      fileType: 'artefact',
      modifiedDate: json['modifiedDate'] != null 
          ? DateTime.parse(json['modifiedDate'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      soundUrl: json['soundUrl'] as String?,
    );
  }

  factory FileChangeRecord.fromBoard(Map<String, dynamic> json) {
    return FileChangeRecord(
      fileId: json['boardId'] as String,
      fileName: json['name'] as String,
      fileType: 'board',
      modifiedDate: json['modifiedDate'] != null 
          ? DateTime.parse(json['modifiedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'fileName': fileName,
      'fileType': fileType,
      'modifiedDate': modifiedDate?.toIso8601String(),
      'imageUrl': imageUrl,
      'soundUrl': soundUrl,
    };
  }

  @override
  String toString() {
    return 'FileChangeRecord(id: $fileId, name: $fileName, type: $fileType, modified: $modifiedDate)';
  }
}

/// Response containing all changes since a specific date
class SyncCheckResponse {
  final List<FileChangeRecord> changedFiles;
  final DateTime checkDate;
  final int totalChanges;

  SyncCheckResponse({
    required this.changedFiles,
    required this.checkDate,
    required this.totalChanges,
  });

  Map<String, dynamic> toJson() {
    return {
      'changedFiles': changedFiles.map((f) => f.toJson()).toList(),
      'checkDate': checkDate.toIso8601String(),
      'totalChanges': totalChanges,
    };
  }

  @override
  String toString() {
    return 'SyncCheckResponse(totalChanges: $totalChanges, checkDate: $checkDate)';
  }
}

/// Service for checking file synchronization status
/// Uses local SQLite database to cache data and track sync state
class SyncService {
  final ApiProvider _apiProvider;
  final Token _token;
  final UserInfo _userInfo;
  final ArtefactRepository _artefactRepo;
  final SavedBoardRepository _boardRepo;
  final CategoryRepository _categoryRepo;
  final UserRepository _userRepo;
  final SavedArtefactRepository _savedArtefactRepo;
  final SyncMetadataRepository _syncMetaRepo;

  SyncService({
    ApiProvider? apiProvider,
    Token? token,
    UserInfo? userInfo,
    ArtefactRepository? artefactRepo,
    SavedBoardRepository? boardRepo,
    CategoryRepository? categoryRepo,
    UserRepository? userRepo,
    SavedArtefactRepository? savedArtefactRepo,
    SyncMetadataRepository? syncMetaRepo,
  })  : _apiProvider = apiProvider ?? GetIt.instance.get<ApiProvider>(),
        _token = token ?? GetIt.instance.get<Token>(),
        _userInfo = userInfo ?? GetIt.instance.get<UserInfo>(),
        _artefactRepo = artefactRepo ?? ArtefactRepository(),
        _boardRepo = boardRepo ?? SavedBoardRepository(),
        _categoryRepo = categoryRepo ?? CategoryRepository(),
        _userRepo = userRepo ?? UserRepository(),
        _savedArtefactRepo = savedArtefactRepo ?? SavedArtefactRepository(),
        _syncMetaRepo = syncMetaRepo ?? SyncMetadataRepository();

  /// Check for files that have been changed since a specific date
  /// Returns a list of changed files with their modification dates
  /// The filtering is done on the backend for better performance
  /// Results are cached in the local SQLite database
  Future<SyncCheckResponse?> checkForChanges(DateTime since) async {
    try {
      // Format the date as ISO 8601 for the query parameter
      final sinceParam = since.toUtc().toIso8601String();
      final apiResponse = await _apiProvider.fetchAsJson(
        'Users/Sync/changes?since=$sinceParam',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
      );

      if (apiResponse != null && apiResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(apiResponse.body);
        
        final changedFiles = (data['changedFiles'] as List<dynamic>)
            .map((file) => FileChangeRecord.fromJson(file as Map<String, dynamic>))
            .toList();
        
        // Update local database with fetched changes
        await _updateLocalDatabase(changedFiles);
        
        // Update sync metadata
        final userId = _userInfo.userId;
        if (userId != null) {
          await _syncMetaRepo.updateLastSyncDate(userId, 'all', DateTime.now());
        }
        
        final syncResponse = SyncCheckResponse(
          changedFiles: changedFiles,
          checkDate: DateTime.parse(data['checkDate'] as String),
          totalChanges: data['totalChanges'] as int,
        );
        return syncResponse;
      }
      return null;
    } catch (e) {
      print('[SYNC] ERROR in checkForChanges: $e');
      return null;
    }
  }

  /// Query local database for changes since a specific date
  /// This checks the local SQLite database without calling the API
  Future<SyncCheckResponse?> checkLocalChanges(DateTime since) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return null;

      final List<FileChangeRecord> changedFiles = [];
      final sinceTimestamp = since.millisecondsSinceEpoch ~/ 1000;

      // Query local artefacts
      final artefacts = await _artefactRepo.getByUserId(userId);
      int artefactChanges = 0;
      for (final artefact in artefacts) {
        if (artefact.modifiedDate != null && artefact.modifiedDate! > sinceTimestamp) {
          artefactChanges++;
          final record = FileChangeRecord(
            fileId: artefact.artefactId,
            fileName: artefact.name ?? 'Unnamed Artefact',
            fileType: 'artefact',
            modifiedDate: DateTime.fromMillisecondsSinceEpoch(artefact.modifiedDate! * 1000),
            imageUrl: artefact.imagePath,
            soundUrl: artefact.soundPath,
          );
          changedFiles.add(record);
        }
      }

      // Query local boards
      final boards = await _boardRepo.getByUserId(userId);
      int boardChanges = 0;
      for (final board in boards) {
        if (board.modifiedDate != null && board.modifiedDate! > sinceTimestamp) {
          boardChanges++;
          final record = FileChangeRecord(
            fileId: board.id,
            fileName: board.name,
            fileType: 'board',
            modifiedDate: DateTime.fromMillisecondsSinceEpoch(board.modifiedDate! * 1000),
          );
          changedFiles.add(record);
        }
      }

      // Sort by modification date (most recent first)
      changedFiles.sort((a, b) {
        if (a.modifiedDate == null && b.modifiedDate == null) return 0;
        if (a.modifiedDate == null) return 1;
        if (b.modifiedDate == null) return -1;
        return b.modifiedDate!.compareTo(a.modifiedDate!);
      });

      final response = SyncCheckResponse(
        changedFiles: changedFiles,
        checkDate: DateTime.now(),
        totalChanges: changedFiles.length,
      );
      return response;
    } catch (e) {
      print('[SYNC-LOCAL] ERROR in checkLocalChanges: $e');
      return null;
    }
  }

  /// Sync data from server to local database
  /// Downloads complete entity data from the server and updates the local SQLite database
  Future<bool> syncFromServer({DateTime? since}) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return false;

      final syncDate = since ?? DateTime.now().subtract(const Duration(days: 365));

      // Sync all entities from API
      int totalSynced = 0;
      
      // 1. Sync artefacts (bidirectional)
      final artefactsResponse = await _apiProvider.fetchAsJson(
        'Users/Artefacts',
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );
      
      List<String> syncedArtefactIds = [];
      if (artefactsResponse != null && artefactsResponse.statusCode == 200) {
        final List<dynamic> artefactsData = json.decode(artefactsResponse.body);
        for (final data in artefactsData) {
          await _syncArtefact(data);
          syncedArtefactIds.add(data['artefactId'] as String);
          totalSynced++;
        }
      }
      
      // Upload local artefacts that don't exist on backend or are newer
      await _uploadLocalArtefacts(syncedArtefactIds);

      // 2. Sync categories (bidirectional)
      final categoriesResponse = await _apiProvider.fetchAsJson(
        'Users/Categories',
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );
      
      List<String> syncedCategoryIds = [];
      if (categoriesResponse != null && categoriesResponse.statusCode == 200) {
        final List<dynamic> categoriesData = json.decode(categoriesResponse.body);
        for (final data in categoriesData) {
          await _syncCategory(data);
          syncedCategoryIds.add(data['categoryId'] as String);
          totalSynced++;
        }
      }
      
      // Upload local categories that don't exist on backend or are newer
      await _uploadLocalCategories(syncedCategoryIds);

      // 3. Sync boards (bidirectional)
      final boardsResponse = await _apiProvider.fetchAsJson(
        'Users/Boards',
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );
      
      List<String> syncedBoardIds = [];
      if (boardsResponse != null && boardsResponse.statusCode == 200) {
        final List<dynamic> boardsData = json.decode(boardsResponse.body);
        for (final data in boardsData) {
          await _syncBoard(data);
          syncedBoardIds.add(data['boardId'] as String? ?? data['id'] as String);
          totalSynced++;
        }
      }
      
      // Upload local boards that don't exist on backend or are newer
      await _uploadLocalBoards(syncedBoardIds);

      // Update sync metadata
      await _syncMetaRepo.updateLastSyncDate(userId, 'all', DateTime.now());

      return true;
    } catch (e) {
      print('[SYNC] ERROR in syncFromServer: $e');
      return false;
    }
  }

  /// Update local database with fetched file changes
  Future<void> _updateLocalDatabase(List<FileChangeRecord> changes) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return;

      int updatedArtefacts = 0;
      int updatedBoards = 0;
      int missingArtefacts = 0;
      int missingBoards = 0;

      for (final change in changes) {
        if (change.fileType == 'artefact') {
          // Check if artefact exists locally
          final existing = await _artefactRepo.getById(change.fileId);
          
          if (existing != null) {
            // Update existing artefact
            final updated = existing.copyWith(
              name: change.fileName,
              imagePath: change.imageUrl,
              soundPath: change.soundUrl,
              modifiedDate: change.modifiedDate != null 
                  ? change.modifiedDate!.millisecondsSinceEpoch ~/ 1000 
                  : null,
            );
            await _artefactRepo.update(updated);
            updatedArtefacts++;
          } else {
            // Note: We can't create new artefacts without full data
            // This would require fetching the full artefact from the API
            missingArtefacts++;
          }
        } else if (change.fileType == 'board') {
          // Similar logic for boards
          final existing = await _boardRepo.getById(change.fileId);
          
          if (existing != null) {
            final updated = existing.copyWith(
              name: change.fileName,
              modifiedDate: change.modifiedDate != null 
                  ? change.modifiedDate!.millisecondsSinceEpoch ~/ 1000 
                  : null,
            );
            await _boardRepo.update(updated);
            updatedBoards++;
          } else {
            missingBoards++;
          }
        }
      }
    } catch (e) {
      print('[SYNC] ERROR in _updateLocalDatabase: $e');
    }
  }

  /// Get all changes grouped by file type
  Future<Map<String, List<FileChangeRecord>>?> checkForChangesGrouped(
      DateTime since) async {
    final syncResponse = await checkForChanges(since);
    
    if (syncResponse == null) return null;

    final Map<String, List<FileChangeRecord>> grouped = {
      'artefact': [],
      'board': [],
    };

    for (final change in syncResponse.changedFiles) {
      grouped[change.fileType]?.add(change);
    }

    return grouped;
  }

  /// Get a summary of changes as a simple map
  /// Uses the backend summary endpoint for better performance
  Future<Map<String, int>?> getChangeSummary(DateTime since) async {
    try {
      final sinceParam = since.toUtc().toIso8601String();
      
      final response = await _apiProvider.fetchAsJson(
        'Users/Sync/summary?since=$sinceParam',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        return {
          'total': data['totalChanges'] as int,
          'artefacts': data['artefactChanges'] as int,
          'boards': data['boardChanges'] as int,
        };
      }
      return null;
    } catch (e) {
      print('Error getting change summary: $e');
      return null;
    }
  }

  /// Check if there are any changes since the given date
  Future<bool> hasChanges(DateTime since) async {
    final summary = await getChangeSummary(since);
    return summary != null && summary['total']! > 0;
  }

  /// Get the last sync date for the current user
  /// Returns null if no sync has been performed yet
  Future<DateTime?> getLastSyncDate() async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return null;

      return await _syncMetaRepo.getLastSyncDate(userId, 'all');
    } catch (e) {
      print('Error getting last sync date: $e');
      return null;
    }
  }

  /// Set the last sync date for the current user
  Future<void> setLastSyncDate(DateTime date) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return;

      await _syncMetaRepo.updateLastSyncDate(userId, 'all', date);
    } catch (e) {
      print('Error setting last sync date: $e');
    }
  }

  /// Check if local database needs syncing
  /// Returns true if last sync was more than the specified duration ago
  Future<bool> needsSync({Duration threshold = const Duration(hours: 1)}) async {
    final lastSync = await getLastSyncDate();
    if (lastSync == null) return true;

    final now = DateTime.now();
    final timeSinceSync = now.difference(lastSync);
    return timeSinceSync > threshold;
  }

  /// Perform a full sync if needed
  /// Checks if sync is needed based on threshold and performs sync if necessary
  Future<bool> autoSync({Duration threshold = const Duration(hours: 1)}) async {
    if (await needsSync(threshold: threshold)) {
      return await syncFromServer();
    }
    return true; // Already synced recently
  }

  /// Get count of items in local database
  Future<Map<String, int>> getLocalItemCounts() async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return {'artefacts': 0, 'boards': 0};

      final artefacts = await _artefactRepo.getByUserId(userId);
      final boards = await _boardRepo.getByUserId(userId);

      return {
        'artefacts': artefacts.length,
        'boards': boards.length,
      };
    } catch (e) {
      print('[SYNC] ERROR getting local item counts: $e');
      return {'artefacts': 0, 'boards': 0};
    }
  }

  /// Helper to check if an item should be synced based on modified dates
  /// Returns 'download' if backend is newer, 'upload' if local is newer, 'skip' if equal/unknown
  String _decideSyncDirection(int? localModifiedDate, int? backendModifiedDate) {
    // Local null - pull from server (server is source of truth)
    if (localModifiedDate == null) {
      return 'download';
    }
    
    // Local exists but backend doesn't - upload to server
    if (localModifiedDate != null && backendModifiedDate == null) {
      return 'upload';
    }
    
    // Both exist - compare dates
    if (backendModifiedDate! > localModifiedDate!) {
      return 'download'; // Backend is newer
    } else if (localModifiedDate > backendModifiedDate) {
      return 'upload'; // Local is newer
    } else {
      return 'skip'; // Same date, no sync needed
    }
  }

  /// Helper method to sync a single artefact from API data to local database
  Future<void> _syncArtefact(Map<String, dynamic> data) async {
    try {
      final artefactId = data['artefactId'] as String?;
      if (artefactId == null) return;

      final existing = await _artefactRepo.getById(artefactId);
      
      // Check if we need to sync based on modified dates
      final backendModifiedDate = _parseDate(data['modifiedDate'] as String?);
      final syncDirection = _decideSyncDirection(existing?.modifiedDate, backendModifiedDate);
      
      if (syncDirection == 'skip') {
        return; // Already in sync
      } else if (syncDirection == 'upload') {
        // Local is newer, upload to server
        if (existing != null) {
          await _uploadArtefact(existing);
        }
        return;
      }
      
      // syncDirection == 'download' - Download from server
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
    } catch (e, stackTrace) {
      print('[SYNC] ERROR syncing artefact: $e');
    }
  }

  /// Helper method to sync a single category from API data to local database
  Future<void> _syncCategory(Map<String, dynamic> data) async {
    try {
      final categoryId = data['categoryId'] as String?;
      if (categoryId == null) return;

      final existing = await _categoryRepo.getById(categoryId);
      
      // Check if we need to sync based on modified dates
      final backendModifiedDate = _parseDate(data['modifiedDate'] as String?);
      final syncDirection = _decideSyncDirection(existing?.modifiedDate, backendModifiedDate);
      
      if (syncDirection == 'skip') {
        return; // Already in sync
      } else if (syncDirection == 'upload') {
        // Local is newer, upload to server
        if (existing != null) {
          await _uploadCategory(existing);
        }
        return;
      }
      
      // syncDirection == 'download' - Download from server
      // Download category image if it has a URL
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
    } catch (e, stackTrace) {
      print('[SYNC] ERROR syncing category: $e');
    }
  }

  /// Helper method to sync a single board from API data to local database
  Future<void> _syncBoard(Map<String, dynamic> data) async {
    try {
      final boardId = data['boardId'] as String? ?? data['id'] as String?;
      if (boardId == null) return;

      final existing = await _boardRepo.getById(boardId);
      
      // Check if we need to sync based on modified dates
      final backendModifiedDate = _parseDate(data['modifiedDate'] as String?);
      final syncDirection = _decideSyncDirection(existing?.modifiedDate, backendModifiedDate);
      
      if (syncDirection == 'skip') {
        return; // Already in sync
      } else if (syncDirection == 'upload') {
        // Local is newer, upload to server
        if (existing != null) {
          await _uploadBoard(existing);
        }
        return;
      }
      
      // syncDirection == 'download' - Download from server
      // Parse artefact IDs and saved artefact data
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
        createdDate: _parseDate(data['createdDate'] as String?) ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
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
    } catch (e, stackTrace) {
      print('[SYNC] ERROR syncing board: $e');
    }
  }

  /// Upload local artefacts that don't exist on backend or are newer
  Future<void> _uploadLocalArtefacts(List<String> syncedIds) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return;

      // Get all local artefacts for this user
      final localArtefacts = await _artefactRepo.getByUserId(userId);
      
      for (final artefact in localArtefacts) {
        // Skip if already synced from backend
        if (syncedIds.contains(artefact.artefactId)) continue;
        
        // This artefact exists locally but not on backend, upload it
        final backendId = await _uploadArtefact(artefact);
        if (backendId != null) {
          syncedIds.add(backendId);
        }
      }
    } catch (e) {
      print('[SYNC] ERROR uploading local artefacts: $e');
    }
  }

  /// Upload local categories that don't exist on backend or are newer
  Future<void> _uploadLocalCategories(List<String> syncedIds) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return;

      // Get all local categories for this user
      final localCategories = await _categoryRepo.getByUserId(userId);
      
      for (final category in localCategories) {
        // Skip if already synced from backend
        if (syncedIds.contains(category.categoryId)) continue;
        
        // This category exists locally but not on backend, upload it
        await _uploadCategory(category);
      }
    } catch (e) {
      print('[SYNC] ERROR uploading local categories: $e');
    }
  }

  /// Upload local boards that don't exist on backend or are newer
  Future<void> _uploadLocalBoards(List<String> syncedIds) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return;

      // Get all local boards for this user
      final localBoards = await _boardRepo.getByUserId(userId);
      
      for (final board in localBoards) {
        // Skip if already synced from backend
        if (syncedIds.contains(board.id)) continue;
        
        // This board exists locally but not on backend, upload it
        await _uploadBoard(board);
      }
    } catch (e) {
      print('[SYNC] ERROR uploading local boards: $e');
    }
  }

  /// Upload a single artefact to the backend
  Future<String?> _uploadArtefact(ArtefactDB artefact) async {
    try {
      // Prepare multipart request
      final uri = Uri.parse(_apiProvider.baseUrl + 'Users/Artefacts');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${_token.value}';
      
      // Add artefact data fields
      request.fields['UserId'] = _userInfo.userId ?? '';
      request.fields['ArtefactId'] = artefact.artefactId;
      request.fields['Name'] = artefact.name ?? '';
      request.fields['NameShown'] = (artefact.nameShown == 1).toString();
      if (artefact.categoryId != null) {
        request.fields['CategoryId'] = artefact.categoryId!;
      }
      
      // Upload image file if it exists locally
      if (artefact.imagePath != null) {
        final imageFile = await _getLocalFile('Artefacts', artefact.imagePath!, _userInfo.userId ?? '');
        if (imageFile != null && await imageFile.exists()) {
          request.files.add(await http.MultipartFile.fromPath('Image', imageFile.path));
        }
      }
      
      // Upload sound file if it exists locally
      if (artefact.soundPath != null) {
        final soundFile = await _getLocalFile('Sounds', artefact.soundPath!, _userInfo.userId ?? '');
        if (soundFile != null && await soundFile.exists()) {
          request.files.add(await http.MultipartFile.fromPath('Sound', soundFile.path));
        }
      }
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response to get the backend's artefact ID
        try {
          final responseData = json.decode(responseBody);
          final backendArtefactId = responseData['artefactId'] as String?;
          return backendArtefactId;
        } catch (e) {
          print('[SYNC] ERROR: Could not parse artefact ID from response: $e');
        }
      } else {
        print('[SYNC] ERROR: Failed to upload artefact ${artefact.artefactId}: ${response.statusCode}');
        print('[SYNC] Response: $responseBody');
      }
      return null;
    } catch (e, stackTrace) {
      print('[SYNC] ERROR uploading artefact: $e');
      print('[SYNC] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Upload a single category to the backend
  Future<void> _uploadCategory(CategoryDB category) async {
    try {
      // Prepare multipart request
      final uri = Uri.parse(_apiProvider.baseUrl + 'Users/Categories');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${_token.value}';
      
      // Add category data fields
      request.fields['UserId'] = _userInfo.userId ?? '';
      request.fields['CategoryId'] = category.categoryId;
      request.fields['Name'] = category.name ?? '';
      
      // Upload image file if it exists locally
      if (category.imagePath != null) {
        final imageFile = await _getLocalFile('Categories', category.imagePath!, _userInfo.userId ?? '');
        if (imageFile != null && await imageFile.exists()) {
          request.files.add(await http.MultipartFile.fromPath('Image', imageFile.path));
        }
      }
      
      final response = await request.send();
      if (response.statusCode != 200 && response.statusCode != 201) {
        final responseBody = await response.stream.bytesToString();
        print('[SYNC] ERROR: Failed to upload category ${category.categoryId}: ${response.statusCode}');
        print('[SYNC] Response: $responseBody');
      }
    } catch (e) {
      print('[SYNC] ERROR uploading category: $e');
    }
  }

  /// Upload a single board to the backend
  Future<void> _uploadBoard(SavedBoardDB board) async {
    try {
      final response = await _apiProvider.postAsJson(
        'Users/Boards',
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
      
      if (response == null || (response.statusCode != 200 && response.statusCode != 201)) {
        print('[SYNC] ERROR: Failed to upload board ${board.id}: ${response?.statusCode}');
      }
    } catch (e) {
      print('[SYNC] ERROR uploading board: $e');
    }
  }

  /// Get a local file from the synced assets directory
  Future<File?> _getLocalFile(String assetType, String filename, String userId) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final file = File('${appDir.path}/Synced/$assetType/$userId/$filename');
      return file;
    } catch (e) {
      return null;
    }
  }

  /// Helper method to sync a saved artefact (board item placement)
  Future<void> _syncSavedArtefact(Map<String, dynamic> data, String boardId) async {
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
        createdDate: _parseDate(data['createdDate'] as String?) ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
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
    } catch (e, stackTrace) {
      print('[SYNC] ERROR syncing saved artefact: $e');
    }
  }

  /// Helper to extract filename from URL
  String? _extractFilename(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final segments = uri.pathSegments;
    return segments.isNotEmpty ? segments.last : url;
  }

  /// Helper to download an asset (image or sound) from the server
  /// Returns the local filename if successful, null otherwise
  Future<String?> _downloadAsset(
    String url, 
    String assetType,
    String filename,
    String userId,
  ) async {
    try {
      // Construct the full URL if it's a relative path
      final fullUrl = url.startsWith('http') 
          ? url 
          : _apiProvider.baseUrl + url;
      
      // Download the file
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );
      
      if (response.statusCode != 200) {
        print('[SYNC] Failed to download asset: ${response.statusCode} - $fullUrl');
        return null;
      }
      
      // Get the application support directory (writable location)
      final appDir = await getApplicationSupportDirectory();
      
      // Create the directory structure: AppSupport/Synced/{assetType}/{userId}/
      final assetDir = Directory('${appDir.path}/Synced/$assetType/$userId');
      if (!await assetDir.exists()) {
        await assetDir.create(recursive: true);
      }
      
      // Write the file without extension (matching backend storage)
      final file = File('${assetDir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);
      
      // Return just the filename for storage in the database
      return filename;
    } catch (e) {
      print('[SYNC] ERROR downloading asset from $url: $e');
      return null;
    }
  }

  /// Helper to parse date string to Unix timestamp (seconds)
  int? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final dateTime = DateTime.parse(dateStr);
      return dateTime.millisecondsSinceEpoch ~/ 1000;
    } catch (e) {
      print('[SYNC] Error parsing date: $dateStr - $e');
      return null;
    }
  }
}
