import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/artifact.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ArtifactBoard extends StatefulWidget {
  //To add initial artifacts to the board
  final List<Widget>? artifacts;

  //To define height and witdh of widget
  final double? height;
  final double? width;
  final Color? backgroundColor;

  const ArtifactBoard({
    super.key,
    this.artifacts,
    this.height = 100,
    this.width = 100,
    this.backgroundColor = Colors.white,
  });

  @override
  State<StatefulWidget> createState() => _ArtifactBoardState();

  bool isWithinBoard(Offset offset) {
    // Assuming you have access to the board's dimensions
    double boardWidth = width ?? 0; // Default or assigned width
    double boardHeight = height ?? 0; // Default or assigned height

    return offset.dx >= 0 &&
        offset.dx <= boardWidth &&
        offset.dy >= 0 &&
        offset.dy <= boardHeight;
  }
}

class _ArtifactBoardState extends State<ArtifactBoard> {
  late List<Widget> artifacts;
  late DraggableArtifact artifact;

  @override
  void initState() {
    super.initState();
    artifacts = widget.artifacts ?? [];
    artifact = DraggableArtifact(
      position: const Offset(500, 500),
      target: widget,
      child: Artifact(
        icon: SvgPicture.asset('assets/icons/sillyface.svg'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _control();
  }

  Widget _control() => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            artifact,
          ],
        ),
      );
}
