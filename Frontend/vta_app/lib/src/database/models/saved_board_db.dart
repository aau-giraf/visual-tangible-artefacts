/// SQLite database model for the saved_board table.
class SavedBoardDB {
  final String id;
  final String name;
  final String userId;
  final String? savedArtefactIds; // JSON as TEXT
  final String? artefactIds;
  final String? snapshotPath;
  final int createdDate;
  final int? modifiedDate;
  final int isDeleted;

  SavedBoardDB({
    required this.id,
    required this.name,
    required this.userId,
    this.savedArtefactIds,
    this.artefactIds,
    this.snapshotPath,
    required this.createdDate,
    this.modifiedDate,
    this.isDeleted = 0,
  });

  /// Converts the SavedBoardDB object to a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'saved_artefact_ids': savedArtefactIds,
      'artefact_ids': artefactIds,
      'snapshot_path': snapshotPath,
      'created_date': createdDate,
      'modified_date': modifiedDate,
      'is_deleted': isDeleted,
    };
  }

  /// Creates a SavedBoardDB object from a database Map.
  factory SavedBoardDB.fromMap(Map<String, dynamic> map) {
    return SavedBoardDB(
      id: map['id'] as String,
      name: map['name'] as String,
      userId: map['user_id'] as String,
      savedArtefactIds: map['saved_artefact_ids'] as String?,
      artefactIds: map['artefact_ids'] as String?,
      snapshotPath: map['snapshot_path'] as String?,
      createdDate: map['created_date'] as int,
      modifiedDate: map['modified_date'] as int?,
      isDeleted: map['is_deleted'] as int? ?? 0,
    );
  }

  /// Creates a copy of this SavedBoardDB with the given fields replaced.
  SavedBoardDB copyWith({
    String? id,
    String? name,
    String? userId,
    String? savedArtefactIds,
    String? artefactIds,
    String? snapshotPath,
    int? createdDate,
    int? modifiedDate,
    int? isDeleted,
  }) {
    return SavedBoardDB(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      savedArtefactIds: savedArtefactIds ?? this.savedArtefactIds,
      artefactIds: artefactIds ?? this.artefactIds,
      snapshotPath: snapshotPath ?? this.snapshotPath,
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'SavedBoardDB{id: $id, name: $name, userId: $userId, savedArtefactIds: $savedArtefactIds, artefactIds: $artefactIds, snapshotPath: $snapshotPath, createdDate: $createdDate, modifiedDate: $modifiedDate, isDeleted: $isDeleted}';
  }
}
