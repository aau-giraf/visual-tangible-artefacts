import 'package:get_it/get_it.dart';
import 'package:vta_app/src/database/database.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:vta_app/src/services/sync_downloader.dart';
import 'package:vta_app/src/services/sync_uploader.dart';
import 'package:vta_app/src/services/sync_change_detector.dart';
import 'package:vta_app/src/services/sync_models.dart';
import 'package:logging/logging.dart';

// Re-export models so existing `import 'sync_service.dart'` still works.
export 'package:vta_app/src/services/sync_models.dart';

final _log = Logger('SyncService');

/// High-level orchestrator for bidirectional data sync.
///
/// Delegates to:
/// * [SyncChangeDetector] — remote / local change queries
/// * [SyncDownloader]     — server → local entity sync
/// * [SyncUploader]       — local → server entity sync
///
/// The public API surface is intentionally kept identical to the pre-split
/// version so that [SyncTimer] and other consumers require no changes.
class SyncService {
  final UserInfo _userInfo;
  final ArtefactRepository _artefactRepo;
  final SavedBoardRepository _boardRepo;
  final SyncMetadataRepository _syncMetaRepo;

  final SyncChangeDetector _detector;
  final SyncDownloader _downloader;
  final SyncUploader _uploader;

  SyncService({
    UserInfo? userInfo,
    ArtefactRepository? artefactRepo,
    SavedBoardRepository? boardRepo,
    SyncMetadataRepository? syncMetaRepo,
    SyncChangeDetector? detector,
    SyncDownloader? downloader,
    SyncUploader? uploader,
  })  : _userInfo = userInfo ?? GetIt.instance.get<UserInfo>(),
        _artefactRepo = artefactRepo ?? ArtefactRepository(),
        _boardRepo = boardRepo ?? SavedBoardRepository(),
        _syncMetaRepo = syncMetaRepo ?? SyncMetadataRepository(),
        _detector = detector ?? SyncChangeDetector(),
        _downloader = downloader ?? SyncDownloader(),
        _uploader = uploader ?? SyncUploader();

  // ── Bidirectional sync ────────────────────────────────────────

  /// Download all entities from the server, then upload any that are
  /// missing on the backend. Updates the sync-metadata timestamp.
  Future<bool> syncFromServer({DateTime? since}) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return false;

      // 1. Download all entity types, collecting synced IDs
      final syncedArtefactIds = await _downloader.downloadArtefacts();
      await _uploader.uploadLocalArtefacts(syncedArtefactIds);

      final syncedCategoryIds = await _downloader.downloadCategories();
      await _uploader.uploadLocalCategories(syncedCategoryIds);

      final syncedBoardIds = await _downloader.downloadBoards();
      await _uploader.uploadLocalBoards(syncedBoardIds);

      // 2. Mark sync timestamp
      await _syncMetaRepo.updateLastSyncDate(userId, 'all', DateTime.now());

      return true;
    } catch (e) {
      _log.info('[SYNC] ERROR in syncFromServer: $e');
      return false;
    }
  }

  /// Perform a full sync if needed (based on [threshold]).
  Future<bool> autoSync(
      {Duration threshold = const Duration(hours: 1)}) async {
    if (await needsSync(threshold: threshold)) {
      return await syncFromServer();
    }
    return true;
  }

  // ── Change detection (delegated) ──────────────────────────────

  /// Forwarded to [SyncChangeDetector.checkForChanges].
  Future<SyncCheckResponse?> checkForChanges(DateTime since) =>
      _detector.checkForChanges(since);

  /// Forwarded to [SyncChangeDetector.checkLocalChanges].
  Future<SyncCheckResponse?> checkLocalChanges(DateTime since) =>
      _detector.checkLocalChanges(since);

  /// Forwarded to [SyncChangeDetector.checkForChangesGrouped].
  Future<Map<String, List<FileChangeRecord>>?> checkForChangesGrouped(
          DateTime since) =>
      _detector.checkForChangesGrouped(since);

  /// Forwarded to [SyncChangeDetector.getChangeSummary].
  Future<Map<String, int>?> getChangeSummary(DateTime since) =>
      _detector.getChangeSummary(since);

  /// Forwarded to [SyncChangeDetector.hasChanges].
  Future<bool> hasChanges(DateTime since) => _detector.hasChanges(since);

  // ── Sync metadata ─────────────────────────────────────────────

  /// Get the last sync date for the current user.
  Future<DateTime?> getLastSyncDate() async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return null;
      return await _syncMetaRepo.getLastSyncDate(userId, 'all');
    } catch (e) {
      _log.info('Error getting last sync date: $e');
      return null;
    }
  }

  /// Set the last sync date for the current user.
  Future<void> setLastSyncDate(DateTime date) async {
    try {
      final userId = _userInfo.userId;
      if (userId == null) return;
      await _syncMetaRepo.updateLastSyncDate(userId, 'all', date);
    } catch (e) {
      _log.info('Error setting last sync date: $e');
    }
  }

  /// Returns `true` if last sync was more than [threshold] ago.
  Future<bool> needsSync(
      {Duration threshold = const Duration(hours: 1)}) async {
    final lastSync = await getLastSyncDate();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get count of items in local database.
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
      _log.info('[SYNC] ERROR getting local item counts: $e');
      return {'artefacts': 0, 'boards': 0};
    }
  }
}
