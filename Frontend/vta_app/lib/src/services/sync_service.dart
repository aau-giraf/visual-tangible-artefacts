import 'dart:convert';
import 'package:get_it/get_it.dart';
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
      print('[SYNC] checkForChanges called with since: $since');
      print('[SYNC] Current user ID: ${_userInfo.userId}');
      
      // Format the date as ISO 8601 for the query parameter
      final sinceParam = since.toUtc().toIso8601String();
      print('[SYNC] Formatted date parameter: $sinceParam');
      
      print('[SYNC] Making API call to Users/Sync/changes...');
      final apiResponse = await _apiProvider.fetchAsJson(
        'Users/Sync/changes?since=$sinceParam',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
      );

      if (apiResponse != null && apiResponse.statusCode == 200) {
        print('[SYNC] API response received with status 200');
        final Map<String, dynamic> data = json.decode(apiResponse.body);
        print('[SYNC] Response data: ${data.keys}');
        
        final changedFiles = (data['changedFiles'] as List<dynamic>)
            .map((file) => FileChangeRecord.fromJson(file as Map<String, dynamic>))
            .toList();
        print('[SYNC] Parsed ${changedFiles.length} changed files from API');
        for (final file in changedFiles) {
          print('[SYNC]   - ${file.fileType}: ${file.fileName} (${file.fileId}), modified: ${file.modifiedDate}');
        }
        
        // Update local database with fetched changes
        print('[SYNC] Updating local database with ${changedFiles.length} changes...');
        await _updateLocalDatabase(changedFiles);
        print('[SYNC] Local database update complete');
        
        // Update sync metadata
        final userId = _userInfo.userId;
        if (userId != null) {
          print('[SYNC] Updating sync metadata for user $userId');
          await _syncMetaRepo.updateLastSyncDate(userId, 'all', DateTime.now());
          print('[SYNC] Sync metadata updated');
        }
        
        final syncResponse = SyncCheckResponse(
          changedFiles: changedFiles,
          checkDate: DateTime.parse(data['checkDate'] as String),
          totalChanges: data['totalChanges'] as int,
        );
        print('[SYNC] checkForChanges completed successfully: ${syncResponse.totalChanges} total changes');
        return syncResponse;
      }
      print('[SYNC] API response was null or not 200: ${apiResponse?.statusCode}');
      return null;
    } catch (e) {
      print('[SYNC] ERROR in checkForChanges: $e');
      print('[SYNC] Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Query local database for changes since a specific date
  /// This checks the local SQLite database without calling the API
  Future<SyncCheckResponse?> checkLocalChanges(DateTime since) async {
    try {
      print('[SYNC-LOCAL] checkLocalChanges called with since: $since');
      final userId = _userInfo.userId;
      print('[SYNC-LOCAL] User ID: $userId');
      if (userId == null) {
        print('[SYNC-LOCAL] No user ID, returning null');
        return null;
      }

      final List<FileChangeRecord> changedFiles = [];
      final sinceTimestamp = since.millisecondsSinceEpoch ~/ 1000;
      print('[SYNC-LOCAL] Since timestamp: $sinceTimestamp');

      // Query local artefacts
      print('[SYNC-LOCAL] Querying local artefacts...');
      final artefacts = await _artefactRepo.getByUserId(userId);
      print('[SYNC-LOCAL] Found ${artefacts.length} local artefacts');
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
          print('[SYNC-LOCAL]   - Changed artefact: ${record.fileName} (${record.fileId}), modified: ${record.modifiedDate}');
        }
      }
      print('[SYNC-LOCAL] Found $artefactChanges changed artefacts');

      // Query local boards
      print('[SYNC-LOCAL] Querying local boards...');
      final boards = await _boardRepo.getByUserId(userId);
      print('[SYNC-LOCAL] Found ${boards.length} local boards');
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
          print('[SYNC-LOCAL]   - Changed board: ${record.fileName} (${record.fileId}), modified: ${record.modifiedDate}');
        }
      }
      print('[SYNC-LOCAL] Found $boardChanges changed boards');

      // Sort by modification date (most recent first)
      print('[SYNC-LOCAL] Sorting ${changedFiles.length} changed files by date...');
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
      print('[SYNC-LOCAL] checkLocalChanges completed: ${response.totalChanges} total changes');
      return response;
    } catch (e) {
      print('[SYNC-LOCAL] ERROR in checkLocalChanges: $e');
      print('[SYNC-LOCAL] Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Sync data from server to local database
  /// Downloads complete entity data from the server and updates the local SQLite database
  Future<bool> syncFromServer({DateTime? since}) async {
    try {
      print('[SYNC-SERVER] syncFromServer called');
      final userId = _userInfo.userId;
      print('[SYNC-SERVER] User ID: $userId');
      if (userId == null) {
        print('[SYNC-SERVER] No user ID, aborting sync');
        return false;
      }

      final syncDate = since ?? DateTime.now().subtract(const Duration(days: 365));
      print('[SYNC-SERVER] Using sync date: $syncDate');

      // Sync all entities from API
      int totalSynced = 0;
      
      // 1. Sync artefacts
      print('[SYNC-SERVER] Fetching artefacts from API...');
      final artefactsResponse = await _apiProvider.fetchAsJson(
        'Artefacts',
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );
      if (artefactsResponse != null && artefactsResponse.statusCode == 200) {
        final List<dynamic> artefactsData = json.decode(artefactsResponse.body);
        print('[SYNC-SERVER] Received ${artefactsData.length} artefacts from API');
        for (final data in artefactsData) {
          await _syncArtefact(data);
          totalSynced++;
        }
      }

      // 2. Sync categories
      print('[SYNC-SERVER] Fetching categories from API...');
      final categoriesResponse = await _apiProvider.fetchAsJson(
        'Categories',
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );
      if (categoriesResponse != null && categoriesResponse.statusCode == 200) {
        final List<dynamic> categoriesData = json.decode(categoriesResponse.body);
        print('[SYNC-SERVER] Received ${categoriesData.length} categories from API');
        for (final data in categoriesData) {
          await _syncCategory(data);
          totalSynced++;
        }
      }

      // 3. Sync boards
      print('[SYNC-SERVER] Fetching boards from API...');
      final boardsResponse = await _apiProvider.fetchAsJson(
        'Boards',
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );
      if (boardsResponse != null && boardsResponse.statusCode == 200) {
        final List<dynamic> boardsData = json.decode(boardsResponse.body);
        print('[SYNC-SERVER] Received ${boardsData.length} boards from API');
        for (final data in boardsData) {
          await _syncBoard(data);
          totalSynced++;
        }
      }

      // Update sync metadata
      await _syncMetaRepo.updateLastSyncDate(userId, 'all', DateTime.now());

      print('[SYNC-SERVER] Successfully synced $totalSynced total items from server');
      return true;
    } catch (e) {
      print('[SYNC-SERVER] ERROR in syncFromServer: $e');
      print('[SYNC-SERVER] Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Update local database with fetched file changes
  Future<void> _updateLocalDatabase(List<FileChangeRecord> changes) async {
    try {
      print('[SYNC-DB] _updateLocalDatabase called with ${changes.length} changes');
      final userId = _userInfo.userId;
      if (userId == null) {
        print('[SYNC-DB] No user ID, skipping database update');
        return;
      }

      int updatedArtefacts = 0;
      int updatedBoards = 0;
      int missingArtefacts = 0;
      int missingBoards = 0;

      for (final change in changes) {
        if (change.fileType == 'artefact') {
          print('[SYNC-DB] Processing artefact: ${change.fileName} (${change.fileId})');
          // Check if artefact exists locally
          final existing = await _artefactRepo.getById(change.fileId);
          
          if (existing != null) {
            print('[SYNC-DB]   - Found existing artefact, updating...');
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
            print('[SYNC-DB]   - Artefact updated successfully');
          } else {
            // Note: We can't create new artefacts without full data
            // This would require fetching the full artefact from the API
            missingArtefacts++;
            print('[SYNC-DB]   - WARNING: Artefact ${change.fileId} not in local database');
          }
        } else if (change.fileType == 'board') {
          print('[SYNC-DB] Processing board: ${change.fileName} (${change.fileId})');
          // Similar logic for boards
          final existing = await _boardRepo.getById(change.fileId);
          
          if (existing != null) {
            print('[SYNC-DB]   - Found existing board, updating...');
            final updated = existing.copyWith(
              name: change.fileName,
              modifiedDate: change.modifiedDate != null 
                  ? change.modifiedDate!.millisecondsSinceEpoch ~/ 1000 
                  : null,
            );
            await _boardRepo.update(updated);
            updatedBoards++;
            print('[SYNC-DB]   - Board updated successfully');
          } else {
            missingBoards++;
            print('[SYNC-DB]   - WARNING: Board ${change.fileId} not in local database');
          }
        }
      }
      print('[SYNC-DB] Database update complete:');
      print('[SYNC-DB]   - Updated artefacts: $updatedArtefacts');
      print('[SYNC-DB]   - Updated boards: $updatedBoards');
      print('[SYNC-DB]   - Missing artefacts: $missingArtefacts');
      print('[SYNC-DB]   - Missing boards: $missingBoards');
    } catch (e) {
      print('[SYNC-DB] ERROR in _updateLocalDatabase: $e');
      print('[SYNC-DB] Stack trace: ${StackTrace.current}');
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
    print('[SYNC-CHECK] Checking if sync is needed (threshold: $threshold)');
    final lastSync = await getLastSyncDate();
    print('[SYNC-CHECK] Last sync date: $lastSync');
    if (lastSync == null) {
      print('[SYNC-CHECK] No previous sync found, sync needed');
      return true;
    }

    final now = DateTime.now();
    final timeSinceSync = now.difference(lastSync);
    final needsSync = timeSinceSync > threshold;
    print('[SYNC-CHECK] Time since last sync: $timeSinceSync');
    print('[SYNC-CHECK] Needs sync: $needsSync');
    return needsSync;
  }

  /// Perform a full sync if needed
  /// Checks if sync is needed based on threshold and performs sync if necessary
  Future<bool> autoSync({Duration threshold = const Duration(hours: 1)}) async {
    print('[SYNC-AUTO] autoSync called with threshold: $threshold');
    if (await needsSync(threshold: threshold)) {
      print('[SYNC-AUTO] Sync needed, starting syncFromServer...');
      final result = await syncFromServer();
      print('[SYNC-AUTO] syncFromServer result: $result');
      return result;
    }
    print('[SYNC-AUTO] Sync not needed, already synced recently');
    return true; // Already synced recently
  }

  /// Get count of items in local database
  Future<Map<String, int>> getLocalItemCounts() async {
    try {
      print('[SYNC-COUNTS] Getting local item counts...');
      final userId = _userInfo.userId;
      print('[SYNC-COUNTS] User ID: $userId');
      if (userId == null) {
        print('[SYNC-COUNTS] No user ID, returning zeros');
        return {'artefacts': 0, 'boards': 0};
      }

      print('[SYNC-COUNTS] Querying artefacts...');
      final artefacts = await _artefactRepo.getByUserId(userId);
      print('[SYNC-COUNTS] Found ${artefacts.length} artefacts');
      
      print('[SYNC-COUNTS] Querying boards...');
      final boards = await _boardRepo.getByUserId(userId);
      print('[SYNC-COUNTS] Found ${boards.length} boards');

      final counts = {
        'artefacts': artefacts.length,
        'boards': boards.length,
      };
      print('[SYNC-COUNTS] Total counts: $counts');
      return counts;
    } catch (e) {
      print('[SYNC-COUNTS] ERROR getting local item counts: $e');
      print('[SYNC-COUNTS] Stack trace: ${StackTrace.current}');
      return {'artefacts': 0, 'boards': 0};
    }
  }

  /// Helper method to sync a single artefact from API data to local database
  Future<void> _syncArtefact(Map<String, dynamic> data) async {
    try {
      final artefactId = data['artefactId'] as String?;
      if (artefactId == null) return;

      print('[SYNC-ARTEFACT] Syncing artefact: $artefactId');
      
      final existing = await _artefactRepo.getById(artefactId);
      final artefact = ArtefactDB(
        artefactId: artefactId,
        artefactIndex: data['artefactIndex'] as int? ?? 0,
        userId: data['userId'] as String? ?? _userInfo.userId ?? '',
        categoryId: data['categoryId'] as String?,
        imagePath: _extractFilename(data['imageUrl'] as String?),
        soundPath: _extractFilename(data['soundUrl'] as String?),
        modifiedDate: _parseDate(data['modifiedDate'] as String?),
        name: data['name'] as String?,
        nameShown: (data['nameShown'] as bool?) == true ? 1 : 0,
        isDeleted: (data['isDeleted'] as bool?) == true ? 1 : 0,
      );

      if (existing != null) {
        await _artefactRepo.update(artefact);
        print('[SYNC-ARTEFACT] Updated artefact: $artefactId');
      } else {
        await _artefactRepo.insert(artefact);
        print('[SYNC-ARTEFACT] Inserted new artefact: $artefactId');
      }
    } catch (e) {
      print('[SYNC-ARTEFACT] ERROR syncing artefact: $e');
    }
  }

  /// Helper method to sync a single category from API data to local database
  Future<void> _syncCategory(Map<String, dynamic> data) async {
    try {
      final categoryId = data['categoryId'] as String?;
      if (categoryId == null) return;

      print('[SYNC-CATEGORY] Syncing category: $categoryId');
      
      final existing = await _categoryRepo.getById(categoryId);
      final category = CategoryDB(
        categoryId: categoryId,
        categoryIndex: data['categoryIndex'] as int?,
        userId: data['userId'] as String? ?? _userInfo.userId ?? '',
        name: data['name'] as String?,
        imagePath: _extractFilename(data['imageUrl'] as String?),
        modifiedDate: _parseDate(data['modifiedDate'] as String?),
        usageCount: data['usageCount'] as int? ?? 0,
        lastUsedDate: _parseDate(data['lastUsedDate'] as String?),
        isDeleted: (data['isDeleted'] as bool?) == true ? 1 : 0,
      );

      if (existing != null) {
        await _categoryRepo.update(category);
        print('[SYNC-CATEGORY] Updated category: $categoryId');
      } else {
        await _categoryRepo.insert(category);
        print('[SYNC-CATEGORY] Inserted new category: $categoryId');
      }
    } catch (e) {
      print('[SYNC-CATEGORY] ERROR syncing category: $e');
    }
  }

  /// Helper method to sync a single board from API data to local database
  Future<void> _syncBoard(Map<String, dynamic> data) async {
    try {
      final boardId = data['boardId'] as String? ?? data['id'] as String?;
      if (boardId == null) return;

      print('[SYNC-BOARD] Syncing board: $boardId');
      
      final existing = await _boardRepo.getById(boardId);
      
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
        print('[SYNC-BOARD] Updated board: $boardId');
      } else {
        await _boardRepo.insert(board);
        print('[SYNC-BOARD] Inserted new board: $boardId');
      }

      // Sync saved artefacts for this board
      final savedArtefacts = data['savedArtefacts'] as List<dynamic>?;
      if (savedArtefacts != null) {
        for (final savedArtefactData in savedArtefacts) {
          await _syncSavedArtefact(savedArtefactData, boardId);
        }
      }
    } catch (e) {
      print('[SYNC-BOARD] ERROR syncing board: $e');
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
    } catch (e) {
      print('[SYNC-SAVED-ARTEFACT] ERROR syncing saved artefact: $e');
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
