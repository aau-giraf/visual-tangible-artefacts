/// SQLite database model for the sync_metadata table.
class SyncMetadataDB {
  final int? id;
  final String userId;
  final String entityType; // 'artefact' or 'board'
  final int lastSyncDate; // Unix timestamp (seconds)
  final int lastCheckDate; // Unix timestamp (seconds)

  SyncMetadataDB({
    this.id,
    required this.userId,
    required this.entityType,
    required this.lastSyncDate,
    required this.lastCheckDate,
  });

  /// Converts the SyncMetadataDB object to a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'entity_type': entityType,
      'last_sync_date': lastSyncDate,
      'last_check_date': lastCheckDate,
    };
  }

  /// Creates a SyncMetadataDB object from a database Map.
  factory SyncMetadataDB.fromMap(Map<String, dynamic> map) {
    return SyncMetadataDB(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      entityType: map['entity_type'] as String,
      lastSyncDate: map['last_sync_date'] as int,
      lastCheckDate: map['last_check_date'] as int,
    );
  }

  /// Creates a copy of this SyncMetadataDB with the given fields replaced.
  SyncMetadataDB copyWith({
    int? id,
    String? userId,
    String? entityType,
    int? lastSyncDate,
    int? lastCheckDate,
  }) {
    return SyncMetadataDB(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
      lastCheckDate: lastCheckDate ?? this.lastCheckDate,
    );
  }

  @override
  String toString() {
    return 'SyncMetadataDB{id: $id, userId: $userId, entityType: $entityType, lastSyncDate: $lastSyncDate, lastCheckDate: $lastCheckDate}';
  }
}
