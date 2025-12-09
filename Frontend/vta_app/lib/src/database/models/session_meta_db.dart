/// SQLite database model for the session_meta table.
class SessionMetaDB {
  final int? id; // AUTOINCREMENT, nullable for inserts
  final String? sessionId;
  final String boardId;
  final String userId;
  final int startedAt;
  final int? lastSyncedAt;
  final int isDirty;

  SessionMetaDB({
    this.id,
    this.sessionId,
    required this.boardId,
    required this.userId,
    required this.startedAt,
    this.lastSyncedAt,
    required this.isDirty,
  });

  /// Converts the SessionMetaDB object to a Map for database operations.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'session_id': sessionId,
      'board_id': boardId,
      'user_id': userId,
      'started_at': startedAt,
      'last_synced_at': lastSyncedAt,
      'is_dirty': isDirty,
    };
    
    // Only include id if it's not null (for updates)
    if (id != null) {
      map['id'] = id;
    }
    
    return map;
  }

  /// Creates a SessionMetaDB object from a database Map.
  factory SessionMetaDB.fromMap(Map<String, dynamic> map) {
    return SessionMetaDB(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String?,
      boardId: map['board_id'] as String,
      userId: map['user_id'] as String,
      startedAt: map['started_at'] as int,
      lastSyncedAt: map['last_synced_at'] as int?,
      isDirty: map['is_dirty'] as int,
    );
  }

  /// Creates a copy of this SessionMetaDB with the given fields replaced.
  SessionMetaDB copyWith({
    int? id,
    String? sessionId,
    String? boardId,
    String? userId,
    int? startedAt,
    int? lastSyncedAt,
    int? isDirty,
  }) {
    return SessionMetaDB(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      boardId: boardId ?? this.boardId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  String toString() {
    return 'SessionMetaDB{id: $id, sessionId: $sessionId, boardId: $boardId, userId: $userId, startedAt: $startedAt, lastSyncedAt: $lastSyncedAt, isDirty: $isDirty}';
  }
}
