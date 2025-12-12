// views/linear_board.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import '../../../controllers/linear_board_controller.dart';
import '../../../utilities/audio/artefact_sound_player.dart';

typedef OnArtifactRemoved = void Function(BoardArtefact artifact);
typedef OnArtifactMoved = void Function(BoardArtefact artifact, int fromIndex, int toIndex);

class LinearBoard extends StatefulWidget {
  final Color? backgroundColor;
  final LinearBoardController linearBoardController;
  final OnArtifactRemoved? onArtifactRemoved;
  final OnArtifactMoved? onArtifactMoved;

  const LinearBoard({
    super.key,
    this.backgroundColor,
    required this.linearBoardController,
    this.onArtifactRemoved,
    this.onArtifactMoved,
  });

  @override
  createState() => LinearBoardState();
}

class LinearBoardState extends State<LinearBoard>
    with ArtefactSoundPlayer {
  late LinearBoardController _linearBoardController;

  bool _isDraggingOverTrashCan = false;
  bool _isHoveringTrashCan = false;
  bool _isPlayingAllSounds = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _linearBoardController = widget.linearBoardController;

    _linearBoardController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    cleanupArtefactSounds();
    super.dispose();
  }

  /// Confirmation dialog for removing all artifacts on the board
  void confirmRemoveAllArtifacts() {
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
                _linearBoardController.removeAllArtifacts();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  /// Display a message to the user that the board is full
  void showBoardFullDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: const Text("Board is full."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  /// Helper function for enabling the trashcan animation
  void _enableTrashcanAnimation() {
    setState(() {
      _isDraggingOverTrashCan = true;
    });
  }

  /// Helper function for disabling the animation
  void _disableTrashcanAnimation() {
    setState(() {
      _isDraggingOverTrashCan = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildGrid(context),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final artifacts = _linearBoardController.artifacts
                        .where((a) => a != null && a.baseArtefact != null)
                        .map((a) => a!.baseArtefact!)
                        .toList();

                    if (_isPlayingAllSounds) {
                      await cleanupArtefactSounds();
                      setState(() {
                        _isPlayingAllSounds = false;
                      });
                      return;
                    }

                    // Start playback
                    setState(() {
                      _isPlayingAllSounds = true;
                    });

                    try {
                      for (final artefact in artifacts) {
                        if (!_isPlayingAllSounds) break;
                        await playArtefactSoundAndWait(artefact);
                      }
                    } catch (e) {
                      debugPrint('Error occurred while playing artefact sounds: $e');
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isPlayingAllSounds = false;
                        });
                      }
                    }
                  },
                  icon: Icon(_isPlayingAllSounds ? Icons.stop : Icons.play_arrow),
                  label: Text(_isPlayingAllSounds ? 'Stop Lyde' : 'Afspil Alle Lyde'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlayingAllSounds ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
            _buildInteractiveTrashcan(context),
          ],
        ),

      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < _linearBoardController.fieldCount; i++) ...[
                  _buildBox(context, _linearBoardController.artifacts[i], i),
                  if (i < _linearBoardController.fieldCount - 1)
                    _buildVerticalDivider(context),
                ]
              ],
            ),
            // NOTE: boxes are already added inside the Row above. Avoid
            // duplicating them here, which would place Expanded widgets
            // directly under a Stack (invalid ParentData usage).
          ],
        ),
      ),
    );
  }

  Widget _buildBox(BuildContext context, BoardArtefact? artifact, int index) {
    return Expanded(
      child: DragTarget<BoardArtefact>(
        onAcceptWithDetails: (DragTargetDetails<BoardArtefact> details) {
          int currentIndex =
              _linearBoardController.artifacts.indexOf(details.data);
          if (currentIndex != -1) {
            _linearBoardController.moveArtifact(currentIndex, index);
            // Notify remote controller about the move
            widget.onArtifactMoved?.call(details.data, currentIndex, index);
          }
        },
        builder: (BuildContext context, List<BoardArtefact?> candidateData,
            List<dynamic> rejectedData) {
          return Padding(
            padding: EdgeInsets.all(5),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use the actual available constraints instead of screen size
                // Handle unbounded constraints
                double maxWidth = constraints.maxWidth.isFinite 
                    ? constraints.maxWidth 
                    : MediaQuery.of(context).size.width * 0.15;
                double maxHeight = constraints.maxHeight.isFinite 
                    ? constraints.maxHeight 
                    : MediaQuery.of(context).size.height * 0.35;
                
                double maxSize = maxWidth < maxHeight ? maxWidth : maxHeight;
                
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth.isFinite ? maxWidth : double.infinity,
                    maxHeight: maxHeight.isFinite ? maxHeight : double.infinity,
                  ),
                  child: SizedBox(
                    width: maxWidth.isFinite ? maxWidth : null,
                    height: maxHeight.isFinite ? maxHeight : null,
                    child: artifact == null
                        ? null
                        : _buildDraggableArtifact(
                            context, artifact, index, maxSize),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

   Widget _buildDraggableArtifact(BuildContext context, BoardArtefact artifact,
      int index, double maxSize) {
    // Ensure maxSize is valid and not zero
    double safeMaxSize = maxSize > 0 && maxSize.isFinite ? maxSize : 100;
    double artifactSize = safeMaxSize * 0.9; // Leave some padding
    
    return Draggable<BoardArtefact>(
      data: artifact,
      feedback: Material(
        type: MaterialType.transparency,
        child: Opacity(
          opacity: 0.5,
          child: SizedBox(
            width: artifactSize * 0.8,
            height: artifactSize * 0.8,
            child: artifact.content,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.1,
        child: SizedBox(
          width: artifactSize,
          height: artifactSize,
          child: artifact.content,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.hardEdge,
        child: Center(
          child: artifact.content,
        ),
      ),
    );
  }
  
  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.44,
      width: 1,
      color: Colors.grey,
    );
  }

  Widget _buildInteractiveTrashcan(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
            onTap: () {
              confirmRemoveAllArtifacts();
            },
              child: DragTarget<BoardArtefact>(
                onAcceptWithDetails: (DragTargetDetails<BoardArtefact> details) async {
                  int artifactIndex = _linearBoardController.artifacts.indexOf(details.data);
                  if (artifactIndex != -1) {
                    final candidate = _linearBoardController.artifacts[artifactIndex];

                    if (candidate?.baseArtefact?.categoryId == 'Session-Artefact') {
                      try {
                        final artefactController = GetIt.instance.get<ArtefactController>();
                        final deleted = await artefactController.deleteArtefact(context, candidate!.baseArtefact!);
                        if (deleted) {
                          _linearBoardController.removeArtifact(artifactIndex);
                          // Notify remote session if callback is provided
                          widget.onArtifactRemoved?.call(candidate);
                        } else {
                          // User cancelled deletion: leave artifact in place
                        }
                      } catch (e) {
                        debugPrint('Failed to delete session artefact from server: $e');
                      }
                    } else {
                      // Non-session artefacts: remove locally
                      _linearBoardController.removeArtifact(artifactIndex);
                      // Notify remote session if callback is provided
                      widget.onArtifactRemoved?.call(candidate!);
                    }
                  }
                  _disableTrashcanAnimation();
                },
              onWillAcceptWithDetails: (details) {
                _enableTrashcanAnimation();
                return true;
              },
              onLeave: (details) {
                _disableTrashcanAnimation();
              },
              builder: (BuildContext context,
                  List<BoardArtefact?> candidateData,
                  List<dynamic> rejectedData) {
                return Container(
                  // Defined size to increase target area
                  width: 200,
                  height: 120,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: buildTrashCan(
                    height: _isDraggingOverTrashCan ? 120 : 50,
                    width: _isDraggingOverTrashCan ? 120 : 50,
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget buildTrashCan(
      {double width = 50,
      double height = 50,
      Color color = const Color(0xFFF0F2D9)}) {
    return Container(
      width: width,
      height: height,
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
      child: MouseRegion(
        child: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: _isHoveringTrashCan ? Colors.white : Colors.grey[600],
            size: width * 0.5,
          ),
          onPressed: () {
            confirmRemoveAllArtifacts();
          },
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            hoverColor: const Color.fromARGB(255, 244, 0, 0).withOpacity(0.9),
            shape: const CircleBorder(),
          ),
        ),
        onEnter: (_) {
          setState(() {
            _isHoveringTrashCan = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHoveringTrashCan = false;
          });
        },
      ),
    );
  }
}
