import 'package:flutter/material.dart';
import 'artifact.dart';

class TalkingMat extends StatefulWidget {
  final List<BoardArtefact>? artifacts;
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

class TalkingMatState extends State<TalkingMat> with TickerProviderStateMixin {
  late List<BoardArtefact> artifacts;
  bool isGestureInsideMat = false;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  bool _showDeleteHover = false;
  bool _isDraggingOverTrashCan = false;

  @override
  void initState() {
    super.initState();
    artifacts = widget.artifacts ?? [];
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-2.5, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void addArtifact(BoardArtefact artifact) {
    setState(() {
      artifacts.add(artifact);
    });
  }

  void removeArtifact(GlobalKey artifactKey) {
    artifacts.removeWhere((artifact) => artifact.key == artifactKey);
  }

  void removeAllArtifacts() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm"),
          content: Text("Are you sure you want to remove all artifacts?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Yes"),
              onPressed: () {
                setState(() {
                  artifacts.clear();
                });
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _updateArtifactPosition(BoardArtefact artifact, Offset offset) {
    // Get the rendered size of the artifact if available
    Size? size = artifact.renderedSize;

    if (size != null) {
      // Get the RenderBox of the current widget to handle coordinate conversions
      final RenderBox renderBox = context.findRenderObject() as RenderBox;

      // Convert the global touch/click position to local coordinates
      // This ensures the position is relative to the board's coordinate space
      final localPosition = renderBox.globalToLocal(offset);

      // Update the artifact's position in the state
      // This will trigger a rebuild with the new position
      setState(() {
        artifact.position = localPosition;
      });
    }
  }

  void _loadArtifactSize(BoardArtefact artifact) {
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

  bool _isInsideMat(Offset globalOffset) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    // Get the global position of the top-left corner of the TalkingMat
    final Offset matTopLeftGlobal = renderBox.localToGlobal(Offset.zero);

    // Check if the artifact is inside the mat by comparing global coordinates
    return globalOffset.dx - matTopLeftGlobal.dx >= 0 &&
        globalOffset.dx + matTopLeftGlobal.dx <= renderBox.size.width &&
        globalOffset.dy - matTopLeftGlobal.dy >= 0 &&
        globalOffset.dy + matTopLeftGlobal.dy <= renderBox.size.height;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: widget.height ?? constraints.maxHeight,
          width: widget.width ?? constraints.maxWidth,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...artifacts.map((artifact) {
                _loadArtifactSize(
                    artifact); // Ensure the artifact size is captured
                return Positioned(
                  left: artifact.position?.dx,
                  top: artifact.position?.dy,
                  child: Draggable<BoardArtefact>(
                    data: artifact,
                    feedback: Transform.scale(
                      scale: 1.2,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 5,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Opacity(
                          opacity: 0.5,
                          child: artifact.content,
                        ),
                      ),
                    ),
                    childWhenDragging: Container(),
                    child:
                        Container(key: artifact.key, child: artifact.content),
                    onDragEnd: (details) {
                      if (_isInsideMat(details.offset)) {
                        _updateArtifactPosition(artifact, details.offset);
                      }
                    },
                  ),
                );
              }),
              Align(
                alignment: Alignment.lerp(
                        Alignment.bottomCenter, Alignment.center, 0.1) ??
                    Alignment.bottomCenter,
                child: Stack(alignment: Alignment.center, children: [
                  SlideTransition(
                      position: _offsetAnimation,
                      child: _showDeleteHover
                          ? buildTrashCan(
                              height: 30,
                              width: 30,
                              color: const Color.fromARGB(255, 235, 32, 18))
                          : null),
                  GestureDetector(
                    onTap: () {
                      removeAllArtifacts();
                    },
                    child: DragTarget<BoardArtefact>(
                      builder: (context, data, rejectedData) {
                        return buildTrashCan(
                          height: _isDraggingOverTrashCan ? 120 : 50,
                          width: _isDraggingOverTrashCan ? 120 : 50,
                        );
                      },
                      onAcceptWithDetails: (details) {
                        var artifactKey = details.data.key;
                        removeArtifact(artifactKey);
                        _animationController.reverse();
                        // Listen for the animation status
                        _animationController.addStatusListener((status) {
                          if (status == AnimationStatus.dismissed) {
                            // Wait until animation is fully reversed
                            setState(() {
                              _showDeleteHover = false;
                            });
                          }
                        });
                      },
                      onWillAcceptWithDetails: (details) {
                        setState(() {
                          _showDeleteHover = true;
                          _isDraggingOverTrashCan = true;
                        });
                        _animationController.forward();
                        return true;
                      },
                      onLeave: (details) {
                        _animationController.reverse();
                        _isDraggingOverTrashCan = false;
                        // Listen for the animation status
                        _animationController.addStatusListener((status) {
                          if (status == AnimationStatus.dismissed) {
                            // Wait until animation is fully reversed
                            setState(() {
                              _showDeleteHover = false;
                            });
                          }
                        });
                      },
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTrashCan(
      {double width = 50,
      double height = 50,
      Color color = const Color(0xFFF0F2D9)}) {
    return Stack(children: [
      Container(
        width: width,
        height: width,
        decoration: ShapeDecoration(
          color: color,
          shape: const OvalBorder(),
          shadows: const [
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
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
