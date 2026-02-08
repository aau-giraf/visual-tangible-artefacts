// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/database/database.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:vta_app/src/services/sync_models.dart';

/// Detects what has changed since a given date — locally or on the server.
///
/// All methods are pure queries (no writes). The heavy lifting of actually
/// applying changes lives in [SyncDownloader] / [SyncUploader].
class SyncChangeDetector {
  final ApiProvider _apiProvider;
  final Token _token;
  final UserInfo _userInfo;
  final ArtefactRepository _artefactRepo;
  final SavedBoardRepository _boardRepo;
  final SyncMetadataRepository _syncMetaRepo;

  SyncChangeDetector({
    ApiProvider? apiProvider,
    Token? token,
    UserInfo? userInfo,
    ArtefactRepository? artefactRepo,
    SavedBoardRepository? boardRepo,
    SyncMetadataRepository? syncMetaRepo,
  })  : _apiProvider = apiProvider ?? GetIt.instance.get<ApiProvider>(),
        _token = token ?? GetIt.instance.get<Token>(),
        _userInfo = userInfo ?? GetIt.instance.get<UserInfo>(),
        _artefactRepo = artefactRepo ?? ArtefactRepository(),
        _boardRepo = boardRepo ?? SavedBoardRepository(),
        _syncMetaRepo = syncMetaRepo ?? SyncMetadataRepository();

  // ── Remote change detection ───────────────────────────────────

  /// Check for files that have been changed since [since] on the server.
  ///
  /// Results are cached in the local SQLite database and
  /// the sync-metadata timestamp is updated.
  Future<SyncCheckResponse?> checkForChanges(DateTime since) async {
    try {
      final sinceParam = since.toUtc().toIso8601String();
      final apiResponse = await _apiProvider.fetchAsJson(
        'Sync/changes?since=$sinceParam',
        headers: {'Authorization': 'Bearer ${_token.value}'},
      );

      if (apiResponse != null && apiResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(apiResponse.body);

        final changedFiles = (data['changedFiles'] as List<dynamic>)
            .map((file) =>
                FileChangeRecord.fromJson(file as Map<String, dynamic>))
            .toList();

        // Update local database with fetched changes
        await _updateLocalDatabase(changedFiles);

        // Update sync metadata
        final userId = _userInfo.userId;
        if (userId != null) {
          await _syncMetaRepo.updateLastSyncDate(userId, 'all', DateTime.now());
        }

        return SyncCheckResponse(
          changedFiles: changedFiles,
          checkDate: DateTime.parse(data['checkDate'] as String),
          totalChanges: data['totalChanges'] as int,
        );
      }
      return null;
    } catch (e) {
      print('[SYNC] ERROR in checkForChanges: $e');
      return null;
    }
  }

  /// Get all changes grouped by file type.
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

  /// Get a summary of changes as a simple map.
  ///
  /// Uses the backend summary endpoint for better performance.
  Future<Map<String, int>?> getChangeSummary(DateTime since) async {
    try {
      final sinceParam = since.toUtc().toIso8601String();

      final response = await _apiProvider.fetchAsJson(
        'Sync/summary?since=$sinceParam',
        headers: {'Authorization': 'Bearer ${_token.value}'},
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

  /// Check if there are any changes since the given date.
  Future<bool> hasChanges(DateTime since) async {
    final summary = await getChangeSummary(since);
    return summary != null && summary['total']! > 0;
  }

  // ── Local change detection ────────────────────────────────────

  /// Query local database for changes since [since] (no API call).
  Future<SyncCheckResponse?> checkLocalChanges(DateTime since) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return null;

      final List<FileChangeRecord> changedFiles = [];
      final sinceTimestamp = since.millisecondsSinceEpoch ~/ 1000;

      // Query local artefacts
      final artefacts = await _artefactRepo.getByUserId(userId);
      for (final artefact in artefacts) {
        if (artefact.modifiedDate != null &&
            artefact.modifiedDate! > sinceTimestamp) {
          changedFiles.add(FileChangeRecord(
            fileId: artefact.artefactId,
            fileName: artefact.name ?? 'Unnamed Artefact',
            fileType: 'artefact',
            modifiedDate: DateTime.fromMillisecondsSinceEpoch(
                artefact.modifiedDate! * 1000),
            imageUrl: artefact.imagePath,
            soundUrl: artefact.soundPath,
          ));
        }
      }

      // Query local boards
      final boards = await _boardRepo.getByUserId(userId);
      for (final board in boards) {
        if (board.modifiedDate != null &&
            board.modifiedDate! > sinceTimestamp) {
          changedFiles.add(FileChangeRecord(
            fileId: board.id,
            fileName: board.name,
            fileType: 'board',
            modifiedDate: DateTime.fromMillisecondsSinceEpoch(
                board.modifiedDate! * 1000),
          ));
        }
      }

      // Sort by modification date (most recent first)
      changedFiles.sort((a, b) {
        if (a.modifiedDate == null && b.modifiedDate == null) return 0;
        if (a.modifiedDate == null) return 1;
        if (b.modifiedDate == null) return -1;
        return b.modifiedDate!.compareTo(a.modifiedDate!);
      });

      return SyncCheckResponse(
        changedFiles: changedFiles,
        checkDate: DateTime.now(),
        totalChanges: changedFiles.length,
      );
    } catch (e) {
      print('[SYNC-LOCAL] ERROR in checkLocalChanges: $e');
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────

  /// Apply lightweight metadata updates from [changes] to local DB.
  Future<void> _updateLocalDatabase(List<FileChangeRecord> changes) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return;

      for (final change in changes) {
        if (change.fileType == 'artefact') {
          final existing = await _artefactRepo.getById(change.fileId);
          if (existing != null) {
            final updated = existing.copyWith(
              name: change.fileName,
              imagePath: change.imageUrl,
              soundPath: change.soundUrl,
              modifiedDate: change.modifiedDate != null
                  ? change.modifiedDate!.millisecondsSinceEpoch ~/ 1000
                  : null,
            );
            await _artefactRepo.update(updated);
          }
        } else if (change.fileType == 'board') {
          final existing = await _boardRepo.getById(change.fileId);
          if (existing != null) {
            final updated = existing.copyWith(
              name: change.fileName,
              modifiedDate: change.modifiedDate != null
                  ? change.modifiedDate!.millisecondsSinceEpoch ~/ 1000
                  : null,
            );
            await _boardRepo.update(updated);
          }
        }
      }
    } catch (e) {
      print('[SYNC] ERROR in _updateLocalDatabase: $e');
    }
  }
}
