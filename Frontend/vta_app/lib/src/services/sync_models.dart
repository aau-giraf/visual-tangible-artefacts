/// Data models used by the sync subsystem.
///
/// Extracted from `sync_service.dart` to be shared across
/// [SyncChangeDetector], [SyncDownloader], [SyncUploader], and [SyncService].
library;

// ── SyncResult ──────────────────────────────────────────────────

/// Counts of entities processed during a single entity-type sync pass.
class EntitySyncStats {
  final String entityType;
  int succeeded;
  int failed;
  int skipped;

  EntitySyncStats({
    required this.entityType,
    this.succeeded = 0,
    this.failed = 0,
    this.skipped = 0,
  });

  int get total => succeeded + failed + skipped;

  @override
  String toString() =>
      '$entityType(ok: $succeeded, fail: $failed, skip: $skipped)';
}

/// Detailed record of a single sync error.
class SyncError {
  final String entityType;
  final String? entityId;
  final String message;
  final DateTime timestamp;

  SyncError({
    required this.entityType,
    this.entityId,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'SyncError($entityType${entityId != null ? '/$entityId' : ''}: $message)';
}

/// Aggregated result of a full bidirectional sync operation.
///
/// Replaces the old `bool` return from [SyncService.syncFromServer].
class SyncResult {
  final Map<String, EntitySyncStats> downloadStats;
  final Map<String, EntitySyncStats> uploadStats;
  final List<SyncError> errors;
  final DateTime startedAt;
  final DateTime completedAt;

  SyncResult({
    required this.downloadStats,
    required this.uploadStats,
    List<SyncError>? errors,
    required this.startedAt,
    DateTime? completedAt,
  })  : errors = errors ?? [],
        completedAt = completedAt ?? DateTime.now();

  /// `true` when every entity type completed without errors.
  bool get success => errors.isEmpty;

  /// `true` when at least one entity synced but there were also errors.
  bool get partial =>
      errors.isNotEmpty &&
      (downloadStats.values.any((s) => s.succeeded > 0) ||
          uploadStats.values.any((s) => s.succeeded > 0));

  int get totalDownloaded =>
      downloadStats.values.fold(0, (sum, s) => sum + s.succeeded);

  int get totalUploaded =>
      uploadStats.values.fold(0, (sum, s) => sum + s.succeeded);

  int get totalFailed =>
      downloadStats.values.fold(0, (sum, s) => sum + s.failed) +
      uploadStats.values.fold(0, (sum, s) => sum + s.failed);

  Duration get duration => completedAt.difference(startedAt);

  /// Create a failed result when sync cannot even start (e.g. no user ID).
  factory SyncResult.aborted(String reason) {
    final now = DateTime.now();
    return SyncResult(
      downloadStats: {},
      uploadStats: {},
      errors: [SyncError(entityType: 'sync', message: reason)],
      startedAt: now,
      completedAt: now,
    );
  }

  @override
  String toString() {
    final buf = StringBuffer('SyncResult(');
    buf.write('success: $success, ');
    buf.write('downloaded: $totalDownloaded, ');
    buf.write('uploaded: $totalUploaded, ');
    buf.write('failed: $totalFailed, ');
    buf.write('errors: ${errors.length}, ');
    buf.write('duration: ${duration.inMilliseconds}ms');
    buf.write(')');
    return buf.toString();
  }
}

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
