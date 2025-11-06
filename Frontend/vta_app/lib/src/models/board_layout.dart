// Models for board layout data
class BoardArtefactLayout {
  final String artefactId;
  final double posX;
  final double posY;
  final double width;
  final double height;

  BoardArtefactLayout({
    required this.artefactId,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
  });

  factory BoardArtefactLayout.fromJson(Map<String, dynamic> json) {
    return BoardArtefactLayout(
      artefactId: json['artefactId'] as String,
      posX: (json['posX'] as num).toDouble(),
      posY: (json['posY'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'artefactId': artefactId,
      'posX': posX,
      'posY': posY,
      'width': width,
      'height': height,
    };
  }

  BoardArtefactLayout copyWith({
    String? artefactId,
    double? posX,
    double? posY,
    double? width,
    double? height,
  }) {
    return BoardArtefactLayout(
      artefactId: artefactId ?? this.artefactId,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

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

class UpdateArtefactLayoutRequest {
  final String artefactId;
  final double posX;
  final double posY;
  final double width;
  final double height;

  UpdateArtefactLayoutRequest({
    required this.artefactId,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'artefactId': artefactId,
      'posX': posX,
      'posY': posY,
      'width': width,
      'height': height,
    };
  }
}