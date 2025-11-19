import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:vta_app/src/controllers/talkingmat_controller.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'board_artifact.dart';
import '_long_press_option_wheel.dart';

class TalkingMat extends StatefulWidget {
  final List<BoardArtefact>? artifacts;
  final TalkingmatController controller;
  final double? width;
  final double? height;
  final Color? backgroundColor;

  TalkingMat({
    super.key,
    this.artifacts,
    required TalkingmatController controller, // REQUIRED - never create a new controller
    this.width,
    this.height,
    this.backgroundColor,
  }) : controller = controller {
    debugPrint('[TalkingMat] WIDGET CREATED with controller: ${controller.hashCode}, artifacts: ${artifacts?.length ?? 'null'}');
  }

  @override
  createState() => TalkingMatState();
}

class TalkingMatState extends State<TalkingMat> {
  late List<BoardArtefact> artifacts;
  bool isGestureInsideMat = false;
  bool _isDraggingOverTrashCan = false;
  bool _isHoveringTrashCan = false;
  bool _isPlayingAllSounds = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    artifacts = widget.artifacts ?? [];
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
    final String artifactId = artifact.baseArtefact?.artefactId ?? 'unknown';

    debugPrint('[TalkingMat] _updateArtifactPosition - Artifact ID:$artifactId, global offset: $offset, renderedSize: $size');

    if (size != null) {
      // Get the RenderBox of the current widget to handle coordinate conversions
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      
      if (renderBox == null) {
        debugPrint('[TalkingMat] _updateArtifactPosition - WARNING: Could not get RenderBox');
        return;
      }

      debugPrint('[TalkingMat] _updateArtifactPosition - RenderBox size: ${renderBox.size}');

      // Convert the global touch/click position to local coordinates
      // This ensures the position is relative to the board's coordinate space
      final localPosition = renderBox.globalToLocal(offset);
      debugPrint('[TalkingMat] _updateArtifactPosition - Local position: $localPosition');

      // Clamp the position to keep the artifact within bounds
      // Account for the artifact's own size to prevent it from going off-screen
      final double maxX = renderBox.size.width - size.width;
      final double maxY = renderBox.size.height - size.height;
      final clampedX = localPosition.dx.clamp(0.0, maxX);
      final clampedY = localPosition.dy.clamp(0.0, maxY);
      
      if (localPosition.dx != clampedX || localPosition.dy != clampedY) {
        debugPrint('[TalkingMat] _updateArtifactPosition - Position clamped: ($localPosition.dx, $localPosition.dy) -> ($clampedX, $clampedY)');
      }

      // Store position as relative (0.0-1.0) so it scales with window size
      final double relX = clampedX / renderBox.size.width;
      final double relY = clampedY / renderBox.size.height;
      final Offset newRelativePos = Offset(relX, relY);

      debugPrint('[TalkingMat] _updateArtifactPosition - Storing relative position: $newRelativePos (from absolute: $clampedX, $clampedY)');

      // Update the artifact's position in the state
      // This will trigger a rebuild with the new position
      setState(() {
        artifact.position = newRelativePos;
      });
      
      // Also notify the controller to trigger ValueListenableBuilder rebuild
      if (widget.controller.value.isNotEmpty) {
        final currentList = List<BoardArtefact>.from(widget.controller.value);
        debugPrint('[TalkingMat] _updateArtifactPosition: Setting controller value with ${currentList.length} artifacts');
        widget.controller.value = currentList;
      } else {
        debugPrint('[TalkingMat] _updateArtifactPosition: WARNING - Controller value is empty, not updating!');
      }
    } else {
      debugPrint('[TalkingMat] _updateArtifactPosition - WARNING: Artifact renderedSize is null, cannot update position');
    }
  }

 

  /// Play all artefact sounds on the board sequentially
  Future<void> _playAllArtefactSounds() async {
    if (_isPlayingAllSounds) {
      // If already playing, stop the current playback
      await _audioPlayer.stop();
      setState(() {
        _isPlayingAllSounds = false;
      });
      return;
    }

    setState(() {
      _isPlayingAllSounds = true;
    });

    print('Debug: TalkingMat - Total artefacts on board: ${widget.controller.value.length}');
    
    // Debug each artefact
    for (var artifact in widget.controller.value) {
      print('Debug: TalkingMat - Artefact ID: ${artifact.baseArtefact?.artefactId}, soundUrl: ${artifact.baseArtefact?.soundUrl}');
    }
    
    final artefacts = widget.controller.value
        .where((artifact) => artifact.baseArtefact?.soundUrl?.isNotEmpty == true)
        .toList();

    if (artefacts.isEmpty) {
      print('Debug: TalkingMat - No artefacts with sound found on the board');
      setState(() {
        _isPlayingAllSounds = false;
      });
      return;
    }

    print('Debug: Playing ${artefacts.length} artefact sounds sequentially on TalkingMat');

    try {
      for (var boardArtefact in artefacts) {
        if (_isPlayingAllSounds) {
          try {
            final token = GetIt.instance.get<Token>().value;
            final apiProvider = GetIt.instance.get<ApiProvider>();
            
            if (token != null) {
              final audioUrl = '${apiProvider.baseUrl}Users/Artefacts/${boardArtefact.baseArtefact!.artefactId}/play-audio';
              print('Debug: Playing sound for artefact ${boardArtefact.baseArtefact!.artefactId}');
              
              // Fetch audio data with proper authentication
              final response = await http.get(
                Uri.parse(audioUrl),
                headers: {
                  'Authorization': 'Bearer $token',
                },
              );
              
              if (response.statusCode == 200) {
                // Set audio source from bytes and play
                await _audioPlayer.setAudioSource(
                  AudioSource.uri(Uri.dataFromBytes(response.bodyBytes, mimeType: 'audio/mpeg')),
                );
                await _audioPlayer.play();
              } else {
                print('Debug: Failed to fetch audio - Status: ${response.statusCode}');
                continue; // Skip to next artefact
              }
              
              // Wait for the audio to complete before playing the next one
              await _audioPlayer.playerStateStream
                  .firstWhere((state) => state.processingState == ProcessingState.completed);
              
              print('Debug: Finished playing sound for artefact ${boardArtefact.baseArtefact!.artefactId}');
            }
          } catch (e) {
            print('Debug: Error playing sound for artefact ${boardArtefact.baseArtefact?.artefactId}: $e');
            // Continue to next artefact even if this one fails
          }
        }
      }
    } finally {
      setState(() {
        _isPlayingAllSounds = false;
      });
    }
    
    print('Debug: Finished playing all artefact sounds on TalkingMat');
  }

  void _loadArtifactSize(BoardArtefact artifact) {
    // Access the size of the artifact's content after it has been rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          artifact.key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        final String artifactId = artifact.baseArtefact?.artefactId ?? 'unknown';
        
        if (artifact.renderedSize != size) {
          debugPrint('[TalkingMat] Artifact ID:$artifactId - Rendered size updated: ${artifact.renderedSize} -> $size');
        }
        
        // Update the rendered size in the artifact
        artifact.renderedSize = size;
      } else {
        final String artifactId = artifact.baseArtefact?.artefactId ?? 'unknown';
        debugPrint('[TalkingMat] Artifact ID:$artifactId - WARNING: Could not get RenderBox, key.currentContext is null');
      }
    });
  }

  bool _isInsideMat(Offset globalOffset) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    // Get the global position of the top-left corner of the TalkingMat
    final Offset matTopLeftGlobal = renderBox.localToGlobal(Offset.zero);
    final Size matSize = renderBox.size;

    final double matRight = matTopLeftGlobal.dx + matSize.width;
    final double matBottom = matTopLeftGlobal.dy + matSize.height;

    
     // Check if the artifact is inside the mat by comparing global coordinates
   return globalOffset.dx >= matTopLeftGlobal.dx &&
          globalOffset.dx <= matRight &&
          globalOffset.dy >= matTopLeftGlobal.dy &&
          globalOffset.dy <= matBottom;   
          
   
  }
  

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure constraints are valid and finite
        double matWidth = widget.width ?? constraints.maxWidth;
        double matHeight = widget.height ?? constraints.maxHeight;
        
        // Validate and clamp to reasonable values
        if (!matWidth.isFinite || matWidth <= 0) {
          matWidth = MediaQuery.of(context).size.width * 0.8;
        }
        if (!matHeight.isFinite || matHeight <= 0) {
          matHeight = MediaQuery.of(context).size.height * 0.6;
        }
        // Ensure minimum size
        matWidth = matWidth.clamp(100.0, double.infinity);
        matHeight = matHeight.clamp(100.0, double.infinity);
        
        // Debug mat dimensions
        debugPrint('[TalkingMat] LayoutBuilder - Constraints: ${constraints.maxWidth.toInt()}x${constraints.maxHeight.toInt()}, Mat: ${matWidth.toInt()}x${matHeight.toInt()}');
        
        return SizedBox(
          height: matHeight.isFinite ? matHeight : constraints.maxHeight,
          width: matWidth.isFinite ? matWidth : constraints.maxWidth,
          child: Container(
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
          child: ValueListenableBuilder<List<BoardArtefact>>(
            valueListenable: widget.controller,
            builder: (context, artefacts, child) {
              // Debug: Track artifact count and mat dimensions
              debugPrint('[TalkingMat] Building with ${artefacts.length} artifacts, mat: ${matWidth.toInt()}x${matHeight.toInt()}, controller.value.length=${widget.controller.value.length}');
              
              // Critical: Check if controller value is empty but we expect artifacts
              if (artefacts.isEmpty && widget.controller.value.isEmpty) {
                debugPrint('[TalkingMat] WARNING: Controller value is empty! This should not happen unless explicitly cleared.');
                debugPrint('[TalkingMat] Controller value identity: ${widget.controller.value.hashCode}, controller identity: ${widget.controller.hashCode}');
              } else if (artefacts.length != widget.controller.value.length) {
                debugPrint('[TalkingMat] WARNING: Mismatch! artefacts.length=${artefacts.length} but controller.value.length=${widget.controller.value.length}');
                debugPrint('[TalkingMat] ValueListenableBuilder received ${artefacts.length} but controller has ${widget.controller.value.length}');
              }
              
              // Build the stack directly - artifacts use relative positioning so they don't need key-based rebuilds
              return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ...artefacts.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final BoardArtefact artefact = entry.value;
                      
                      _loadArtifactSize(artefact);
                      
                      // Calculate display position without mutating artifact.position during build
                      Offset displayPosition;
                      
                      // Get or initialize relative position (0.0-1.0)
                      Offset relPosition = artefact.position ?? Offset(0.5, 0.5);
                      final String artifactId = artefact.baseArtefact?.artefactId ?? 'unknown';
                      
                      debugPrint('[TalkingMat] Artifact[$index] ID:$artifactId - Stored position: $relPosition');
                      
                      // Convert old absolute positions to relative if needed (> 1.0 means absolute)
                      if (relPosition.dx > 1.0 || relPosition.dy > 1.0) {
                        debugPrint('[TalkingMat] Artifact[$index] ID:$artifactId - Converting absolute position ${relPosition.dx.toInt()},${relPosition.dy.toInt()} to relative');
                        // Convert absolute to relative - use current mat size
                        relPosition = Offset(
                          (relPosition.dx / matWidth).clamp(0.0, 1.0),
                          (relPosition.dy / matHeight).clamp(0.0, 1.0),
                        );
                        debugPrint('[TalkingMat] Artifact[$index] ID:$artifactId - Converted to relative: $relPosition');
                        // Update artifact position after build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && artefact.position != relPosition) {
                            debugPrint('[TalkingMat] Artifact[$index] ID:$artifactId - PostFrame: Updating stored position from ${artefact.position} to $relPosition');
                            if (widget.controller.value.isNotEmpty) {
                              artefact.position = relPosition;
                              // Force a rebuild by updating the controller's value
                              final currentList = List<BoardArtefact>.from(widget.controller.value);
                              debugPrint('[TalkingMat] PostFrame (convert): Setting controller value with ${currentList.length} artifacts');
                              widget.controller.value = currentList;
                            } else {
                              debugPrint('[TalkingMat] PostFrame (convert): WARNING - Controller value is empty, skipping update!');
                            }
                          }
                        });
                      } else {
                        // Already relative, just normalize
                        relPosition = Offset(
                          relPosition.dx.clamp(0.0, 1.0),
                          relPosition.dy.clamp(0.0, 1.0),
                        );
                      }
                      
                      // Convert relative to absolute for display
                      double absX = relPosition.dx * matWidth;
                      double absY = relPosition.dy * matHeight;
                      debugPrint('[TalkingMat] Artifact[$index] ID:$artifactId - Converted to absolute: $absX, $absY (before clamping)');
                      
                      // Calculate artifact size - use a percentage of mat size as fallback
                      // This ensures artifacts always have a valid size even if renderedSize is null
                      double defaultArtifactSize = (matWidth < matHeight ? matWidth : matHeight) * 0.25;
                      defaultArtifactSize = defaultArtifactSize.clamp(80.0, 200.0);
                      
                      double artifactSize = artefact.renderedSize?.width ?? defaultArtifactSize;
                      debugPrint('[TalkingMat] Artifact[$index] ID:$artifactId - Size: renderedSize=${artefact.renderedSize}, default=$defaultArtifactSize, final=$artifactSize');
                      
                      // Ensure artifact size is reasonable relative to mat
                      artifactSize = artifactSize.clamp(50.0, matWidth * 0.4);
                      artifactSize = artifactSize.clamp(50.0, matHeight * 0.4);
                      
                      // Clamp to ensure artifact stays fully visible
                      final double maxX = (matWidth - artifactSize).clamp(0.0, matWidth);
                      final double maxY = (matHeight - artifactSize).clamp(0.0, matHeight);
                      final double originalAbsX = absX;
                      final double originalAbsY = absY;
                      absX = absX.clamp(0.0, maxX);
                      absY = absY.clamp(0.0, maxY);
                      
                      if (originalAbsX != absX || originalAbsY != absY) {
                        debugPrint('[TalkingMat] Artifact[$index] ID:$artifactId - Position clamped from ($originalAbsX, $originalAbsY) to ($absX, $absY) (max: $maxX, $maxY)');
                      }
                      
                      displayPosition = Offset(absX, absY);
                      debugPrint('[TalkingMat] Artifact[$index] ID:$artifactId - Final display position: $displayPosition');
                      
                      // Update stored position if it changed significantly (only if different from current)
                      final double newRelX = absX / matWidth;
                      final double newRelY = absY / matHeight;
                      if (artefact.position == null || 
                          (newRelX - relPosition.dx).abs() > 0.01 || 
                          (newRelY - relPosition.dy).abs() > 0.01) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            final currentPos = artefact.position;
                            if (currentPos == null || 
                                (currentPos.dx - newRelX).abs() > 0.01 ||
                                (currentPos.dy - newRelY).abs() > 0.01) {
                              debugPrint('[TalkingMat] Artifact[$index] ID:$artifactId - PostFrame: Updating stored relative position from $currentPos to ($newRelX, $newRelY)');
                              artefact.position = Offset(newRelX, newRelY);
                              // Force a rebuild by updating the controller's value
                              // Only update if we still have artifacts
                              if (widget.controller.value.isNotEmpty) {
                                final currentList = List<BoardArtefact>.from(widget.controller.value);
                                debugPrint('[TalkingMat] PostFrame: Setting controller value with ${currentList.length} artifacts');
                                widget.controller.value = currentList;
                              } else {
                                debugPrint('[TalkingMat] PostFrame: WARNING - Controller value is empty, not updating!');
                              }
                            }
                          }
                        });
                      }
                      
                      return Positioned(
                        left: displayPosition.dx,
                        top: displayPosition.dy,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: matWidth * 0.3,
                            maxHeight: matHeight * 0.3,
                          ),
                          child: LongPressOptionWheel(
                            artifact: artefact,
                            child: Draggable<BoardArtefact>(
                              data: artefact,
                              feedback: Transform.scale(
                                scale: 1.2,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: matWidth * 0.3 * 1.2,
                                    maxHeight: matHeight * 0.3 * 1.2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 216, 216, 216).withOpacity(0.15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Opacity(
                                    opacity: 0.5,
                                    child: artefact.content,
                                  ),
                                ),
                              ),
                              childWhenDragging: Container(),
                              child: Container(key: artefact.key, child: artefact.content),
                              onDragEnd: (details) {
                                if (_isInsideMat(details.offset)) {
                                  _updateArtifactPosition(artefact, details.offset);
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                Align(
                  alignment: Alignment.lerp(
                          Alignment.bottomCenter, Alignment.center, 0.1) ??
                      Alignment.bottomCenter,
                  child: DragTarget<BoardArtefact>(
                        builder: (context, data, rejectedData) {
                          double screenWidth = MediaQuery.of(context).size.width;
                          double baseSize = screenWidth > 600 ? 50 : 35;
                          double expandedSize = screenWidth > 600 ? 120 : 80;
                          final size = _isDraggingOverTrashCan ? expandedSize : baseSize;
                          return buildTrashCan(
                            height: size,
                            width: size,
                          );
                        },
                        onAcceptWithDetails: (details) {
                          var artefact = details.data;
                          widget.controller.removeArtifact(artefact);
                          setState(() {
                            _isDraggingOverTrashCan = false;
                          });
                        },
                        onWillAcceptWithDetails: (details) {
                          setState(() {
                            _isDraggingOverTrashCan = true;
                          });
                          return true;
                        },
                        onLeave: (details) {
                          setState(() {
                            _isDraggingOverTrashCan = false;
                          });
                        },
                    ),
                ),

              ],
              );
            },
          ),
        ),
        );
      },
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
            widget.controller.removeAllArtifacts(context: context);
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