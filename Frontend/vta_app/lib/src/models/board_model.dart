import 'dart:math';
import '../ui/widgets/board/board_artifact.dart';

class Board {
  final String id;
  String title;
  
  // State for TalkingMat (Free positioning)
  List<BoardArtefact> talkingMatArtifacts;
  
  // State for LinearBoard (Grid/Slot positioning)
  // Nulls represent empty slots
  List<BoardArtefact?> linearBoardArtifacts;
  
  // View mode preference for this board
  bool showDirectional;
  
  // Linear board field count preference
  int linearBoardFieldCount;

  Board({
    String? id,
    required this.title,
    List<BoardArtefact>? talkingMatArtifacts,
    List<BoardArtefact?>? linearBoardArtifacts,
    this.showDirectional = false,
    this.linearBoardFieldCount = 4,
  }) : 
    this.id = id ?? _generateId(),
    this.talkingMatArtifacts = talkingMatArtifacts ?? [],
    this.linearBoardArtifacts = linearBoardArtifacts ?? List.filled(4, null);

  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';
  }

  Board copyWith({
    String? title,
    List<BoardArtefact>? talkingMatArtifacts,
    List<BoardArtefact?>? linearBoardArtifacts,
    bool? showDirectional,
    int? linearBoardFieldCount,
  }) {
    return Board(
      id: id,
      title: title ?? this.title,
      talkingMatArtifacts: talkingMatArtifacts ?? this.talkingMatArtifacts,
      linearBoardArtifacts: linearBoardArtifacts ?? this.linearBoardArtifacts,
      showDirectional: showDirectional ?? this.showDirectional,
      linearBoardFieldCount: linearBoardFieldCount ?? this.linearBoardFieldCount,
    );
  }
}
