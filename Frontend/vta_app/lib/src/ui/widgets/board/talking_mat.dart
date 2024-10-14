import 'package:flutter/material.dart';
import 'artifact.dart';

class TalkingMat extends StatefulWidget {
  final List<Artifact>? artifacts;
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const TalkingMat({
    super.key,
    this.artifacts,
    this.width,
    this.height,
    this.backgroundColor,
  });

  @override
  createState() => _TalkingMatState();
}

class _TalkingMatState extends State<TalkingMat> {
  late List<Artifact> artifacts;

  @override
  void initState() {
    super.initState();
    artifacts = widget.artifacts ?? [];
  }

  void _updateArtifactPosition(Artifact artifact, Offset offset) {
    // Retrieve the stored size for the artifact
    Size? size = artifact.renderedSize;

    if (size != null) {
      // Offset the position by half of the width and height to center it on the drag end
      setState(() {
        artifact.position =
            Offset(offset.dx - size.width / 2, offset.dy - size.height / 2);
      });
    }
  }

  void _getArtifactSize(Artifact artifact) {
    // Access the size of the artifact's content after it has been rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          artifact.key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;

        // Update the rendered size in the artifact
        artifact.renderedSize = size;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: artifacts.map((artifact) {
          // Call the function to get the size of the artifact once
          _getArtifactSize(artifact);

          return Positioned(
            left: artifact.position.dx,
            top: artifact.position.dy,
            child: Draggable<Artifact>(
              data: artifact,
              feedback: Transform.scale(
                scale: 1.2,
                child: artifact.content,
              ),
              childWhenDragging: Container(),
              child: Container(key: artifact.key, child: artifact.content),
              onDragEnd: (details) {
                _updateArtifactPosition(artifact, details.offset);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
