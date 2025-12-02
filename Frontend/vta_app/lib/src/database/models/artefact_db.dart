/// SQLite database model for the artefact table.
class ArtefactDB {
  final String artefactId;
  final int artefactIndex;
  final String userId;
  final String? categoryId;
  final String? imagePath;
  final String? soundPath;
  final int? modifiedDate;
  final String? name;
  final int nameShown;
  final int isDeleted;

  ArtefactDB({
    required this.artefactId,
    required this.artefactIndex,
    required this.userId,
    this.categoryId,
    this.imagePath,
    this.soundPath,
    this.modifiedDate,
    this.name,
    required this.nameShown,
    this.isDeleted = 0,
  });

  /// Converts the ArtefactDB object to a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'artefact_id': artefactId,
      'artefact_index': artefactIndex,
      'user_id': userId,
      'category_id': categoryId,
      'image_path': imagePath,
      'sound_path': soundPath,
      'modified_date': modifiedDate,
      'name': name,
      'name_shown': nameShown,
      'is_deleted': isDeleted,
    };
  }

  /// Creates an ArtefactDB object from a database Map.
  factory ArtefactDB.fromMap(Map<String, dynamic> map) {
    return ArtefactDB(
      artefactId: map['artefact_id'] as String,
      artefactIndex: map['artefact_index'] as int,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String?,
      imagePath: map['image_path'] as String?,
      soundPath: map['sound_path'] as String?,
      modifiedDate: map['modified_date'] as int?,
      name: map['name'] as String?,
      nameShown: map['name_shown'] as int,
      isDeleted: map['is_deleted'] as int? ?? 0,
    );
  }

  /// Creates a copy of this ArtefactDB with the given fields replaced.
  ArtefactDB copyWith({
    String? artefactId,
    int? artefactIndex,
    String? userId,
    String? categoryId,
    String? imagePath,
    String? soundPath,
    int? modifiedDate,
    String? name,
    int? nameShown,
    int? isDeleted,
  }) {
    return ArtefactDB(
      artefactId: artefactId ?? this.artefactId,
      artefactIndex: artefactIndex ?? this.artefactIndex,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      imagePath: imagePath ?? this.imagePath,
      soundPath: soundPath ?? this.soundPath,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      name: name ?? this.name,
      nameShown: nameShown ?? this.nameShown,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'ArtefactDB{artefactId: $artefactId, artefactIndex: $artefactIndex, userId: $userId, categoryId: $categoryId, imagePath: $imagePath, soundPath: $soundPath, modifiedDate: $modifiedDate, name: $name, nameShown: $nameShown, isDeleted: $isDeleted}';
  }
}
