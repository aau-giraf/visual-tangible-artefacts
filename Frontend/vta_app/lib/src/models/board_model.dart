import 'dart:math';
import 'dart:typed_data';
import '../ui/widgets/board/board_artifact.dart';

class Board {
  final String id;
  String title;

  // Picture shown on this board's tile in the bottom bar
  Uint8List? image;

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
    this.image,
    List<BoardArtefact>? talkingMatArtifacts,
    List<BoardArtefact?>? linearBoardArtifacts,
    this.showDirectional = false,
    this.linearBoardFieldCount = 4,
  })  : id = id ?? _generateId(),
        talkingMatArtifacts = talkingMatArtifacts ?? [],
        linearBoardArtifacts = linearBoardArtifacts ?? List.filled(4, null);

  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';
  }

  Board copyWith({
    String? title,
    Uint8List? image,
    List<BoardArtefact>? talkingMatArtifacts,
    List<BoardArtefact?>? linearBoardArtifacts,
    bool? showDirectional,
    int? linearBoardFieldCount,
  }) {
    return Board(
      id: id,
      title: title ?? this.title,
      image: image ?? this.image,
      talkingMatArtifacts: talkingMatArtifacts ?? this.talkingMatArtifacts,
      linearBoardArtifacts: linearBoardArtifacts ?? this.linearBoardArtifacts,
      showDirectional: showDirectional ?? this.showDirectional,
      linearBoardFieldCount:
          linearBoardFieldCount ?? this.linearBoardFieldCount,
    );
  }
}