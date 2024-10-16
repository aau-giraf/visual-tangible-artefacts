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
  createState() => TalkingMatState();
}

class TalkingMatState extends State<TalkingMat> {
  late List<Artifact> artifacts;
  Size? renderedMatSize;
  bool isGestureInsideMat = false;

  @override
  void initState() {
    super.initState();
    artifacts = widget.artifacts ?? [];
  }

  void addArtifact(Artifact artifact) {
    setState(() {
      artifacts.add(artifact);
    });
  }

  void removeArtifact(GlobalKey artifactKey) {
    artifacts.removeWhere((artifact) => artifact.key == artifactKey);
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

  void _loadArtifactSize(Artifact artifact) {
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

  void _loadMatSize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        renderedMatSize = renderBox.size;
      }
    });
  }

  bool _isInsideMat(Offset localOffset) {
    return localOffset.dx >= 0 &&
        localOffset.dx <= (renderedMatSize?.width ?? 0) &&
        localOffset.dy >= 0 &&
        localOffset.dy <= (renderedMatSize?.height ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    _loadMatSize();
    return GestureDetector(
      onLongPressDown: (details) {
        isGestureInsideMat = true;
        print("long press init");
      },
      onLongPressCancel: () {
        isGestureInsideMat = false;
        print("long press cancelled");
      },
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(children: [
          ...artifacts.map((artifact) {
            // Call the function to get the size of the artifact once
            _loadArtifactSize(artifact);
            return Positioned(
              left: artifact.position.dx,
              top: artifact.position.dy,
              child: Draggable<Artifact>(
                data: artifact,
                feedback: Transform.scale(
                  scale: 1.2,
                  child: PhysicalModel(
                    color: Colors.black,
                    elevation: 20.0,
                    shape: BoxShape.circle,
                    child: artifact.content,
                  ),
                ),
                childWhenDragging: Container(),
                child: Container(key: artifact.key, child: artifact.content),
                onDragEnd: (details) {
                  var localOffset = (context.findRenderObject() as RenderBox)
                      .globalToLocal(details.offset);
                  if (isGestureInsideMat) {
                    _updateArtifactPosition(artifact, details.offset);
                  }
                },
              ),
            );
          }),
          Align(
            alignment:
                Alignment.lerp(Alignment.bottomCenter, Alignment.center, 0.1) ??
                    Alignment.bottomCenter,
            child: DragTarget<Artifact>(
              builder: (context, data, rejectedData) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFF0F2D9),
                    shape: OvalBorder(),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Center(
                    child: Container(
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage('assets/icons/trash_bin.png'),
                              fit: BoxFit.scaleDown)),
                    ),
                  ),
                );
              },
              onAcceptWithDetails: (details) {
                var artifactKey = details.data.key;
                removeArtifact(artifactKey);
              },
            ),
          ),
        ]),
      ),
    );
  }
}
