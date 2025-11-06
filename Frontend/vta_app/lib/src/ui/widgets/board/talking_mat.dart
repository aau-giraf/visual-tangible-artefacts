import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:vta_app/src/controllers/talkingmat_controller.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/models/board_layout.dart';
import 'package:vta_app/src/services/board_layout_service.dart';
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
  final BoardLayoutService _boardLayoutService = BoardLayoutService();
  String? _currentBoardId; // Track the current board being edited
  
  // Debounce timer for auto-save
  Timer? _saveTimer;

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

    // Try to load the current board on initialization
    _loadCurrentBoard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  void addArtifact(BoardArtefact artifact) {
    setState(() {
      artifacts.add(artifact);
      
      // Add listener for size changes to trigger auto-save
      artifact.sizeNotifier.addListener(() {
        _scheduleAutoSave();
      });
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
    
    // Auto-save the board layout after a position change
    _scheduleAutoSave();
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

  /// Auto-save board layout with debouncing to avoid too frequent saves
  void _scheduleAutoSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _autoSaveBoardLayout();
    });
  }

  /// Auto-save the current board layout
  Future<void> _autoSaveBoardLayout() async {
    final layoutData = _getCurrentBoardLayout();
    if (layoutData.isEmpty) {
      print('Debug: No artefacts to save');
      return;
    }

    // If no current board ID, create a default board first
    if (_currentBoardId == null) {
      await _createDefaultBoard();
      if (_currentBoardId == null) {
        print('Debug: Failed to create default board, skipping auto-save');
        return;
      }
    }

    try {
      for (final artefactLayout in layoutData) {
        final request = UpdateArtefactLayoutRequest(
          artefactId: artefactLayout.artefactId,
          posX: artefactLayout.posX,
          posY: artefactLayout.posY,
          width: artefactLayout.width,
          height: artefactLayout.height,
        );

        final success = await _boardLayoutService.updateArtefactLayout(_currentBoardId!, request);
        if (!success) {
          print('Debug: Failed to auto-save layout for artefact ${artefactLayout.artefactId}');
        }
      }
      print('Debug: Auto-saved board layout for ${layoutData.length} artefacts');
    } catch (e) {
      print('Debug: Error auto-saving board layout: $e');
    }
  }

  /// Try to load the current board on initialization
  Future<void> _loadCurrentBoard() async {
    try {
      final boards = await _boardLayoutService.getBoards();
      if (boards != null && boards.isNotEmpty) {
        // Look for a board named "Current Board" or use the most recent one
        final currentBoard = boards.firstWhere(
          (board) => board.name == 'Current Board',
          orElse: () => boards.first, // Fallback to first board if no "Current Board" found
        );
        
        _currentBoardId = currentBoard.boardId;
        print('Debug: Loaded existing board "${currentBoard.name}" with ID: ${currentBoard.boardId}');
        
        // Don't apply positions automatically on startup to avoid overriding user's current layout
        // The board ID is set so auto-save will work from now on
      }
    } catch (e) {
      print('Debug: No existing boards found or error loading: $e');
      // This is fine - a new board will be created when first needed
    }
  }

  /// Create a default board for auto-saving
  Future<void> _createDefaultBoard() async {
    try {
      final defaultBoardName = 'Current Board';
      final layoutData = _getCurrentBoardLayout();
      
      final request = SaveBoardRequest(
        name: defaultBoardName,
        artefacts: layoutData,
      );

      final response = await _boardLayoutService.saveBoard(request);
      if (response != null) {
        _currentBoardId = response.boardId;
        print('Debug: Created default board "${defaultBoardName}" with ID: ${response.boardId}');
      } else {
        print('Debug: Failed to create default board');
      }
    } catch (e) {
      print('Debug: Error creating default board: $e');
    }
  }

  /// Get current board layout data from the artifacts
  List<BoardArtefactLayout> _getCurrentBoardLayout() {
    // Get artifacts from the controller, not the local artifacts list
    final currentArtifacts = widget.controller.value;
    print('Debug: Total artifacts on board: ${currentArtifacts.length}');
    
    // Debug each artifact
    for (int i = 0; i < currentArtifacts.length; i++) {
      final artifact = currentArtifacts[i];
      print('Debug: Artifact $i - baseArtefact: ${artifact.baseArtefact != null}');
      if (artifact.baseArtefact != null) {
        print('Debug: Artifact $i - artefactId: ${artifact.baseArtefact!.artefactId}');
      }
    }
    
    final validArtifacts = currentArtifacts
        .where((artifact) => artifact.baseArtefact != null && artifact.baseArtefact!.artefactId != null)
        .map((artifact) {
      final position = artifact.position ?? Offset.zero;
      final size = artifact.sizeNotifier.value;
      
      print('Debug: Saving artifact ${artifact.baseArtefact!.artefactId} at position (${position.dx}, ${position.dy}) with size (${size.width}, ${size.height})');
      
      return BoardArtefactLayout(
        artefactId: artifact.baseArtefact!.artefactId!,
        posX: position.dx,
        posY: position.dy,
        width: size.width,
        height: size.height,
      );
    }).toList();
    
    print('Debug: Valid artifacts for saving: ${validArtifacts.length}');
    return validArtifacts;
  }

  /// Save the current board as a new saved board
  Future<String?> saveBoardAs(String boardName) async {
    final layoutData = _getCurrentBoardLayout();
    
    final request = SaveBoardRequest(
      name: boardName,
      artefacts: layoutData,
    );

    try {
      final response = await _boardLayoutService.saveBoard(request);
      if (response != null) {
        _currentBoardId = response.boardId;
        print('Debug: Saved board "${boardName}" with ID: ${response.boardId}');
        return response.boardId;
      }
    } catch (e) {
      print('Debug: Error saving board: $e');
    }
    return null;
  }

  /// Load a saved board layout
  Future<void> loadBoard(String boardId) async {
    try {
      final boardLayout = await _boardLayoutService.getBoard(boardId);
      if (boardLayout != null) {
        _currentBoardId = boardId;
        
        // Update artifact positions and sizes using the controller's artifacts
        final currentArtifacts = widget.controller.value;
        for (final artefactLayout in boardLayout.artefacts) {
          final artifact = currentArtifacts.firstWhere(
            (a) => a.baseArtefact?.artefactId == artefactLayout.artefactId,
            orElse: () => throw StateError('Artefact not found'),
          );
          
          setState(() {
            artifact.position = Offset(artefactLayout.posX, artefactLayout.posY);
            artifact.sizeNotifier.value = Size(artefactLayout.width, artefactLayout.height);
          });
        }
        
        print('Debug: Loaded board "${boardLayout.name}" with ${boardLayout.artefacts.length} artefacts');
      }
    } catch (e) {
      print('Debug: Error loading board: $e');
    }
  }

  /// Get list of all saved boards
  Future<List<BoardLayoutResponse>?> getSavedBoards() async {
    try {
      return await _boardLayoutService.getBoards();
    } catch (e) {
      print('Debug: Error getting saved boards: $e');
      return null;
    }
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
                          onAcceptWithDetails: (details) {
                            var artefact = details.data;
                            widget.controller.removeArtifact(artefact);
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