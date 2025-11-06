import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:vta_app/src/controllers/talkingmat_controller.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
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
    TalkingmatController? controller, // Optional parameter
    this.width,
    this.height,
    this.backgroundColor,
  }) : controller = controller ?? TalkingmatController();

  @override
  createState() => TalkingMatState();
}

class TalkingMatState extends State<TalkingMat> with TickerProviderStateMixin {
  late List<BoardArtefact> artifacts;
  // z-order: attached per artefact instance (supports duplicates)
  final Expando<int> _zOrder = Expando<int>('z');
  int _zTick = 0;
  bool isGestureInsideMat = false;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  bool _showDeleteHover = false;
  bool _isDraggingOverTrashCan = false;
  bool _isPlayingAllSounds = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

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
    _audioPlayer.dispose();
    super.dispose();
  }

  void addArtifact(BoardArtefact artifact) {
    setState(() {
      artifacts.add(artifact);
    });
  }

  // Removes artefact by artefactId
  void removeArtifactById(String artefactId) {
    setState(() {
      artifacts.removeWhere((artifact) => artifact.artefactId == artefactId);
    });
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
    Size artSize = artifact.renderedSize ?? const Size(200, 200);

    // Get the RenderBox of the current widget to handle coordinate conversions
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Convert the global touch/click position to local coordinates
    // This ensures the position is relative to the board's coordinate space
    final localPosition = renderBox.globalToLocal(offset);
    final boardSize = renderBox.size;

    // Compute clamped coordinates so the artifact stays inside the board
    final double maxX = math.max(0.0, boardSize.width - artSize.width);
    final double maxY = math.max(0.0, boardSize.height - artSize.height);

    double x = localPosition.dx;
    double y = localPosition.dy;

    x = math.max(0.0, math.min(x, maxX));
    y = math.max(0.0, math.min(y, maxY));

    // Update the artifact's position in the state (clamped)
    setState(() {
      artifact.position = Offset(x, y);
    });
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


  // Access the size of the artifact's content after it has been rendered
  void _loadArtifactSize(GlobalKey key, BoardArtefact artifact) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final optionContext = key.currentContext;
      if (optionContext != null) {
        final renderObject = optionContext.findRenderObject();
        if (renderObject is RenderBox) {
          final size = renderObject.size;
          artifact.renderedSize = size;
        }
      }
    });
  }

  bool _isInsideMat(Offset globalOffset, {Size? artefactSize}) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    final localPos = renderBox.globalToLocal(globalOffset);
    final boardSize = renderBox.size;

    final double artWidth = artefactSize?.width ?? 0.0;
    final double artHeight = artefactSize?.height ?? 0.0;

    final bool insideHoriz = localPos.dx >= 0 && (localPos.dx + artWidth) <= boardSize.width;
    final bool insideVert = localPos.dy >= 0 && (localPos.dy + artHeight) <= boardSize.height;

    return insideHoriz && insideVert;
  }

  // name offset calculation based on text metrics
  double _getNameDisplayOffset(String name, BuildContext context) {
    if (name.isEmpty) return 0.0;
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: name, style: LongPressOptionWheel.nameTextStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout(maxWidth: double.infinity);
    return textPainter.height + 4.0;
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
          child: ValueListenableBuilder<List<BoardArtefact>>(
            valueListenable: widget.controller,
            builder: (context, artefacts, child) {
              // Sort by z-order (ascending), then keep original order as tiebreaker
              final indexed = artefacts.asMap().entries.toList();
              indexed.sort((a, b) {
                final za = _zOrder[a.value] ?? 0;
                final zb = _zOrder[b.value] ?? 0;
                if (za != zb) return za.compareTo(zb);
                return a.key.compareTo(b.key);
              });
              final ordered = indexed.map((e) => e.value).toList();

              final itemWidgets = ordered.map<Widget>((artefact) {
                final measurementKey = GlobalKey();
                _loadArtifactSize(measurementKey, artefact);

                artefact.position ??= Offset(
                  (widget.width ?? constraints.maxWidth) / 2,
                  (widget.height ?? constraints.maxHeight) / 2,
                );

                return Positioned(
                  key: ValueKey('pos-${identityHashCode(artefact)}'),
                  left: artefact.position?.dx,
                  top: artefact.position?.dy,
                  child: LongPressOptionWheel(
                    artifact: artefact,
                    controller: widget.controller,
                    artifactKey: measurementKey,
                    artifactController: GetIt.instance<ArtefactController>(),
                    child: Draggable<BoardArtefact>(
                      data: artefact,
                      feedback: Transform.scale(
                        scale: 1.2,
                        child: Container(
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
                      childWhenDragging: const SizedBox.shrink(),
                      child: RepaintBoundary(
                        key: measurementKey,
                        child: artefact.content,
                      ),
                      onDragStarted: () {
                        setState(() {
                          _zOrder[artefact] = ++_zTick; // bring instance to front
                        });
                      },
                      onDragEnd: (details) {
                        final Size artSize = artefact.renderedSize ?? const Size(200, 200);
                        if (_isInsideMat(details.offset, artefactSize: artSize)) {
                          Offset adjustedPosition = details.offset;
                          if (artefact.baseArtefact?.nameShown == true) {
                            final double nameOffset = _getNameDisplayOffset(
                              artefact.baseArtefact?.name ?? '',
                              context,
                            );
                            adjustedPosition = Offset(
                              details.offset.dx,
                              details.offset.dy - nameOffset,
                            );
                          }
                          _updateArtifactPosition(artefact, adjustedPosition);
                        }
                      },
                    ),
                  ),
                );
              }).toList();

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ...itemWidgets,
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _playAllArtefactSounds();
                        },
                        icon: Icon(_isPlayingAllSounds ? Icons.stop : Icons.play_arrow),
                        label: Text(_isPlayingAllSounds ? 'Stop' : 'Play All'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ),
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
                          widget.controller.removeAllArtifacts(context: context);
                        },
                        child: DragTarget<BoardArtefact>(
                          builder: (context, data, rejectedData) {
                            return buildTrashCan(
                              height: _isDraggingOverTrashCan ? 120 : 50,
                              width: _isDraggingOverTrashCan ? 120 : 50,
                            );
                          },
                          onAcceptWithDetails: (details) async {
                            var artefact = details.data;

                            // If this is a session artefact, ask the controller to delete it
                            // server-side first. Only remove locally after confirmation.
                            if (artefact.baseArtefact?.categoryId == 'Session-Artefact') {
                              try {
                                final artefactController = GetIt.instance.get<ArtefactController>();
                                final deleted = await artefactController.deleteArtefact(context, artefact.baseArtefact!);
                                if (deleted) {
                                  widget.controller.removeArtifact(artefact);
                                } else {
                                  // Deletion cancelled or failed -> leave artefact on the board (restored)
                                }
                              } catch (e) {
                                debugPrint('Failed to delete session artefact from server: $e');
                              }
                            } else {
                              // Non-session artefacts are removed locally immediately
                              widget.controller.removeArtifact(artefact);
                            }

                            _animationController.reverse();
                            _animationController.addStatusListener((status) {
                              if (status == AnimationStatus.dismissed) {
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
                            _animationController.addStatusListener((status) {
                              if (status == AnimationStatus.dismissed) {
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
              );
            },
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