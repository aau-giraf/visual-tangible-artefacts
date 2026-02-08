/// Data models used by the sync subsystem.
///
/// Extracted from `sync_service.dart` to be shared across
/// [SyncChangeDetector], [SyncDownloader], [SyncUploader], and [SyncService].
library;

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
