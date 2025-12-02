/// SQLite database model for the saved_artefact table.
class SavedArtefactDB {
  final String id;
  final String artefactId;
  final String boardId;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final int createdDate;
  final int? modifiedDate;
  final int? nameVisible;
  final int isDeleted;

  SavedArtefactDB({
    required this.id,
    required this.artefactId,
    required this.boardId,
    this.posX = 0,
    this.posY = 0,
    this.width = 200,
    this.height = 200,
    required this.createdDate,
    this.modifiedDate,
    this.nameVisible,
    this.isDeleted = 0,
  });

  /// Converts the SavedArtefactDB object to a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artefact_id': artefactId,
      'board_id': boardId,
      'pos_x': posX,
      'pos_y': posY,
      'width': width,
      'height': height,
      'created_date': createdDate,
      'modified_date': modifiedDate,
      'name_visible': nameVisible,
      'is_deleted': isDeleted,
    };
  }

  /// Creates a SavedArtefactDB object from a database Map.
  factory SavedArtefactDB.fromMap(Map<String, dynamic> map) {
    return SavedArtefactDB(
      id: map['id'] as String,
      artefactId: map['artefact_id'] as String,
      boardId: map['board_id'] as String,
      posX: (map['pos_x'] as num?)?.toDouble() ?? 0,
      posY: (map['pos_y'] as num?)?.toDouble() ?? 0,
      width: (map['width'] as num?)?.toDouble() ?? 200,
      height: (map['height'] as num?)?.toDouble() ?? 200,
      createdDate: map['created_date'] as int,
      modifiedDate: map['modified_date'] as int?,
      nameVisible: map['name_visible'] as int?,
      isDeleted: map['is_deleted'] as int? ?? 0,
    );
  }

  /// Creates a copy of this SavedArtefactDB with the given fields replaced.
  SavedArtefactDB copyWith({
    String? id,
    String? artefactId,
    String? boardId,
    double? posX,
    double? posY,
    double? width,
    double? height,
    int? createdDate,
    int? modifiedDate,
    int? nameVisible,
    int? isDeleted,
  }) {
    return SavedArtefactDB(
      id: id ?? this.id,
      artefactId: artefactId ?? this.artefactId,
      boardId: boardId ?? this.boardId,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      nameVisible: nameVisible ?? this.nameVisible,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'SavedArtefactDB{id: $id, artefactId: $artefactId, boardId: $boardId, posX: $posX, posY: $posY, width: $width, height: $height, createdDate: $createdDate, modifiedDate: $modifiedDate, nameVisible: $nameVisible, isDeleted: $isDeleted}';
  }
}
