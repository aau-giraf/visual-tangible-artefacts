// Models for board layout data
class BoardArtefactLayout {
  final String? savedArtefactId;
  final String artefactId;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final bool? nameVisible;

/// Sets the layout of an artefact on a board, 
/// including its position, size, and visibility of its name.
  BoardArtefactLayout({
    this.savedArtefactId,
    required this.artefactId,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
    this.nameVisible,
  });


/// Creates a BoardArtefactLayout instance from a JSON map.
  factory BoardArtefactLayout.fromJson(Map<String, dynamic> json) {
    return BoardArtefactLayout(
      savedArtefactId: json['savedArtefactId'] as String?,
      artefactId: json['artefactId'] as String,
      posX: (json['posX'] as num).toDouble(),
      posY: (json['posY'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      nameVisible: json['nameVisible'] as bool?,
    );
  }

/// Converts the BoardArtefactLayout instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (savedArtefactId != null) 'savedArtefactId': savedArtefactId,
      'artefactId': artefactId,
      'posX': posX,
      'posY': posY,
      'width': width,
      'height': height,
      if (nameVisible != null) 'nameVisible': nameVisible,
    };
  }

/// Creates a copy of the current BoardArtefactLayout instance with optional new values.
  BoardArtefactLayout copyWith({
    String? artefactId,
    double? posX,
    double? posY,
    double? width,
    double? height,
    bool? nameVisible,
  }) {
    return BoardArtefactLayout(
      artefactId: artefactId ?? this.artefactId,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      nameVisible: nameVisible ?? this.nameVisible,
    );
  }
}

/// Request model for saving a board layout, including its name and artefacts.
class SaveBoardRequest {
  final String name;
  final List<BoardArtefactLayout> artefacts;

  SaveBoardRequest({
    required this.name,
    required this.artefacts,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'artefacts': artefacts.map((a) => a.toJson()).toList(),
    };
  }
}

/// Response model for retrieving a board layout, 
/// including its ID, name, creation and modification dates, and artefacts.
class BoardLayoutResponse {
  final String boardId;
  final String name;
  final DateTime createdDate;
  final DateTime? modifiedDate;
  final List<BoardArtefactLayout> artefacts;

  BoardLayoutResponse({
    required this.boardId,
    required this.name,
    required this.createdDate,
    this.modifiedDate,
    required this.artefacts,
  });

/// Creates a BoardLayoutResponse instance from a JSON map.
  factory BoardLayoutResponse.fromJson(Map<String, dynamic> json) {
    return BoardLayoutResponse(
      boardId: json['boardId'] as String,
      name: json['name'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      modifiedDate: json['modifiedDate'] != null 
          ? DateTime.parse(json['modifiedDate'] as String) 
          : null,
      artefacts: (json['artefacts'] as List<dynamic>)
          .map((a) => BoardArtefactLayout.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Request model for updating the layout of an artefact on a board, 
/// including its position, size, and visibility of its name.
class UpdateArtefactLayoutRequest {
  final String? savedArtefactId;
  final String artefactId;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final bool? nameVisible;

  UpdateArtefactLayoutRequest({
    this.savedArtefactId,
    required this.artefactId,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
    this.nameVisible,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'artefactId': artefactId,
      'posX': posX,
      'posY': posY,
      'width': width,
      'height': height,
    };
    if (savedArtefactId != null) {
      map['savedArtefactId'] = savedArtefactId;
    }
    if (nameVisible != null) {
      map['nameVisible'] = nameVisible;
    }
    return map;
  }
}