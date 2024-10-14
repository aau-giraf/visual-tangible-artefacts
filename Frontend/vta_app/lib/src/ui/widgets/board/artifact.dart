import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/artifact_board.dart';

class DraggableArtifact extends StatefulWidget {
  final Offset position;
  final Artifact? child;
  final ArtifactBoard? target;

  const DraggableArtifact({
    super.key,
    this.position = const Offset(0, 0),
    this.child,
    this.target,
  });

  @override
  State<DraggableArtifact> createState() => _DraggableArtifactState();
}

class _DraggableArtifactState extends State<DraggableArtifact> {
  late Offset position;

  @override
  void initState() {
    super.initState();
    position = widget.position;
  }

  @override
  Widget build(BuildContext context) {
    return _control();
  }

  Widget _control() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable<Offset>(
        feedback: widget.child ?? Container(),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          final newPosition = Offset(
            details.offset.dx - (widget.child?.width ?? 0) / 2,
            details.offset.dy - (widget.child?.height ?? 0) / 2,
          );
          if (widget.target!.isWithinBoard(newPosition)) {
            setState(() {
              position = newPosition;
            });
          }
        },
        child: widget.child ?? Container(),
      ),
    );
  }
}

class Artifact extends StatelessWidget {
  final double? height;
  final double? width;
  final Widget? icon;

  const Artifact({
    super.key,
    this.height,
    this.width,
    this.icon,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      child: icon,
    );
  }
}
