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
import 'package:vta_app/src/utilities/data/data_repository.dart';
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

class TalkingMatState extends State<TalkingMat> with TickerProviderStateMixin, WidgetsBindingObserver {
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
  
  // Flag to prevent auto-saving during certain operations
  bool _inhibitAutoSave = false;
  
  // Track last saved state of each artefact layout to detect changes
  final Map<String, BoardArtefactLayout> _lastSavedLayouts = {};
  
  // Track local artefacts that haven't been matched to saved instances
  late List<BoardArtefact> unmatchedLocal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    artifacts = widget.artifacts ?? [];
    unmatchedLocal = List.from(artifacts);
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
    WidgetsBinding.instance.removeObserver(this);
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


  /// Auto-save board layout with debouncing to avoid too frequent saves
  void _scheduleAutoSave() {
    if (_inhibitAutoSave) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      _autoSaveBoardLayout();
    });
  }

  /// Immediate save without debouncing for critical events
  void _immediateAutoSave() {
    if (_inhibitAutoSave) return;
    _saveTimer?.cancel(); // Cancel any pending debounced save
    _autoSaveBoardLayout(); // Save immediately
  }

  /// Public helper to allow external controllers (e.g., settings or option wheels)
  /// to immediately persist the current board layout, including nameVisible flags.
  Future<void> forceAutoSave() async {
    if (_inhibitAutoSave) return;
    _saveTimer?.cancel();
    await _autoSaveBoardLayout();
  }

  /// Handle app lifecycle changes to save when app loses focus (mobile/tablet specific)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App sent to background (home button pressed, another app opened) - save immediately
        _immediateAutoSave();
        break;
      case AppLifecycleState.detached:
        // App is being terminated - save immediately
        _immediateAutoSave();
        break;
      case AppLifecycleState.inactive:
        // App temporarily lost focus (notification pulled down, phone call, etc.) - save as precaution
        _scheduleAutoSave();
        break;
      case AppLifecycleState.resumed:
        // App came back to foreground from background - no save needed
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still in memory - save immediately
        _immediateAutoSave();
        break;
    }
  }

  /// Check if layout data has changed compared to last saved state
  bool _hasLayoutChanged(BoardArtefactLayout layout) {
    final lastSaved = _lastSavedLayouts[layout.savedArtefactId ?? layout.artefactId];
    if (lastSaved == null) return true; // New artefact
    
    return lastSaved.posX != layout.posX ||
           lastSaved.posY != layout.posY ||
           lastSaved.width != layout.width ||
           lastSaved.height != layout.height ||
           lastSaved.nameVisible != layout.nameVisible;
  }

  /// Update tracking of last saved layout data
  void _updateLastSavedLayouts(List<BoardArtefactLayout> layouts) {
    _lastSavedLayouts.clear();
    for (final layout in layouts) {
      final key = layout.savedArtefactId ?? layout.artefactId;
      _lastSavedLayouts[key] = BoardArtefactLayout(
        artefactId: layout.artefactId,
        savedArtefactId: layout.savedArtefactId,
        posX: layout.posX,
        posY: layout.posY,
        width: layout.width,
        height: layout.height,
        nameVisible: layout.nameVisible,
      );
    }
  }

  /// Auto-save the current board layout
  Future<void> _autoSaveBoardLayout() async {
    final layoutData = _getCurrentBoardLayout();
    if (layoutData.isEmpty) {
      return;
    }

    // If no current board ID, create a default board first
    if (_currentBoardId == null) {
      await _createDefaultBoard();
      if (_currentBoardId == null) {
        return;
      }
    }

    try {
      // Partition layouts into those with saved IDs (update via PATCH) and those without (create via PUT)
      final toPatch = layoutData.where((l) => l.savedArtefactId != null).toList();
      final toCreate = layoutData.where((l) => l.savedArtefactId == null).toList();

      // First, update existing saved instances via PATCH (only if changed)
      final toPatchChanged = toPatch.where((layout) => _hasLayoutChanged(layout)).toList();
      
      for (final artefactLayout in toPatchChanged) {
        final request = UpdateArtefactLayoutRequest(
          savedArtefactId: artefactLayout.savedArtefactId,
          artefactId: artefactLayout.artefactId,
          posX: artefactLayout.posX,
          posY: artefactLayout.posY,
          width: artefactLayout.width,
          height: artefactLayout.height,
          nameVisible: artefactLayout.nameVisible,
        );

        await _boardLayoutService.updateArtefactLayout(_currentBoardId!, request);
      }

      // If there are artefacts without saved IDs, perform a full board update (PUT) to create them in one go
      if (toCreate.isNotEmpty) {
        final saveRequest = SaveBoardRequest(name: 'Current Board', artefacts: layoutData);
        await _boardLayoutService.updateBoard(_currentBoardId!, saveRequest);
      } else {
        // Send the whole board as a single request (POST to create, PUT to update)
        final saveRequest = SaveBoardRequest(name: 'Current Board', artefacts: layoutData);

        final response = await _boardLayoutService.updateBoard(_currentBoardId!, saveRequest);
        if (response != null) {
          // map returned saved artefact ids (in case of reordering/new instances)
          try {
            final current = widget.controller.value;
            final returned = response.artefacts;
            final count = math.min(current.length, returned.length);
            for (var i = 0; i < count; i++) {
              current[i].savedArtefactId = returned[i].savedArtefactId;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      // error auto-saving board layout
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
        // restore the board layout on startup
        await _restoreArtefactsFromBoard(currentBoard);
      }
    } catch (e) {
      // no existing boards found or error loading
      // This is fine - a new board will be created when first needed
    }
  }

  /// Restore artefacts from a saved board layout
  Future<void> _restoreArtefactsFromBoard(BoardLayoutResponse boardLayout) async {
    // restoring artefact instances from saved board
    
    // Clear the current board first to avoid conflicts
    widget.controller.value.clear();
    
    // Add each saved artefact instance to the board
    for (final artefactLayout in boardLayout.artefacts) {
      try {
        // Find the best local match: same artefactId and smallest distance between positions
        BoardArtefact? best;
        double bestDist = double.infinity;
        for (final local in unmatchedLocal) {
          if (local.baseArtefact?.artefactId == artefactLayout.artefactId) {
            final localPos = local.position ?? Offset.zero;
            final dx = localPos.dx - artefactLayout.posX;
            final dy = localPos.dy - artefactLayout.posY;
            final dist = dx * dx + dy * dy; // squared distance
            if (dist < bestDist) {
              bestDist = dist;
              best = local;
            }
          }
        }

        if (best != null) {
          // Assign position/size/saved id to matched local instance
          setState(() {
            best!.position = Offset(artefactLayout.posX, artefactLayout.posY);
            best.sizeNotifier.value = Size(artefactLayout.width, artefactLayout.height);
            best.savedArtefactId = artefactLayout.savedArtefactId;
            // Restore per-instance name visibility if provided
            if (artefactLayout.nameVisible != null) {
              best.nameVisible = artefactLayout.nameVisible!;
            }
          });
          // remove from unmatched list so we don't match it again
          unmatchedLocal.remove(best);
        } else {
          // No local match found: fetch and add a fresh instance
          await _addArtefactToBoard(artefactLayout.artefactId, artefactLayout);
        }
      } catch (e) {
        // error restoring artefact instance
      }
    }
    
    // Notify listeners that the board has been restored
    setState(() {});
  }

  /// Add an artefact to the board by ID with saved layout
  Future<void> _addArtefactToBoard(String artefactId, BoardArtefactLayout layout) async {
    try {
      // Get token for API call
      final token = GetIt.instance.get<Token>();
      if (token.value == null) {
        return;
      }

      // Fetch the artefact data from the API
      final artifactRepository = ArtifactRepository();
      final artefact = await artifactRepository.fetchArtefact(artefactId, token: token.value!);
      
      if (artefact == null) {
        return;
      }

      // Create BoardArtefact from the fetched Artefact
      final boardArtefact = BoardArtefact.fromArtefact(
        artefact,
        headers: {'Authorization': 'Bearer ${token.value}'},
      );

      // Set the position and size from the saved layout
      boardArtefact.position = Offset(layout.posX, layout.posY);
      boardArtefact.sizeNotifier.value = Size(layout.width, layout.height);
  // Set the saved instance id so future updates target this specific instance
  boardArtefact.savedArtefactId = layout.savedArtefactId;
  

  // NOTE: We do NOT override the base artefact's nameShown with the layout's computed value
  // The nameVisible from layout is already computed on the backend (SavedArtefact ?? BaseArtefact ?? User)
  // But we should always display what the base artefact actually says, not override it
  // This ensures that when the base artefact's nameShown changes, all instances update automatically

      // Add it to the controller
      widget.controller.addArtifact(boardArtefact);
      
    } catch (e) {
      // error adding artefact to board
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
        // Map returned saved artefact instance ids back onto the local artifacts
        try {
          final current = widget.controller.value;
          final returned = response.artefacts;
          final count = math.min(current.length, returned.length);
          for (var i = 0; i < count; i++) {
            current[i].savedArtefactId = returned[i].savedArtefactId;
          }
        } catch (_) {
          // ignore mapping errors
        }
      } else {
        // failed to create default board
      }
    } catch (e) {
      // error creating default board
    }
  }

  /// Get current board layout data from the artifacts
  List<BoardArtefactLayout> _getCurrentBoardLayout() {
    // Get artifacts from the controller, not the local artifacts list
    final currentArtifacts = widget.controller.value;
    
    final validArtifacts = currentArtifacts
        .where((artifact) => artifact.baseArtefact != null && artifact.baseArtefact!.artefactId != null)
        .map((artifact) {
      final position = artifact.position ?? Offset.zero;
      final size = artifact.sizeNotifier.value;
      
      // saving artifact layout

      return BoardArtefactLayout(
        savedArtefactId: artifact.savedArtefactId,
        artefactId: artifact.baseArtefact!.artefactId!,
        posX: position.dx,
        posY: position.dy,
        width: size.width,
        height: size.height,
        nameVisible: artifact.nameVisible,
      );
    }).toList();
    
    // valid artifacts for saving: ${validArtifacts.length}
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
        // saved board
        // Map returned saved artefact instance ids back onto local artifacts
        try {
          final current = widget.controller.value;
          final returned = response.artefacts;
          final count = math.min(current.length, returned.length);
          for (var i = 0; i < count; i++) {
            current[i].savedArtefactId = returned[i].savedArtefactId;
          }
        } catch (_) {}

        return response.boardId;
      }
    } catch (e) {
      // error saving board
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
        
        // loaded board
      }
    } catch (e) {
      // error loading board
    }
  }

  /// Get list of all saved boards
  Future<List<BoardLayoutResponse>?> getSavedBoards() async {
    try {
      return await _boardLayoutService.getBoards();
    } catch (e) {
      // error getting saved boards
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
                    child: ValueListenableBuilder<bool>(
                      valueListenable: artefact.showResizeHandle,
                      builder: (context, isResizing, child) {
                        // When resizing, render content directly without Draggable
                        if (isResizing) {
                          return RepaintBoundary(
                            key: measurementKey,
                            child: artefact.content,
                          );
                        }
                        // When not resizing, wrap in Draggable
                        return Draggable<BoardArtefact>(
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
                              if (artefact.nameVisible == true) {
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
                        );
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
                        onTap: () async {
                          // Confirm with the user before deleting everything
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Slet alle artefakter'),
                                content: const Text('Er du sikker på, at du vil slette alle artefakter på denne tavle?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                    child: const Text('Annuller'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                    child: const Text('Slet'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldDelete == true) {
                            // If we have a saved board id, attempt server-side clear first
                            if (_currentBoardId != null) {
                              try {
                                final ok = await _boardLayoutService.deleteAllSavedArtefacts(_currentBoardId!);
                                if (!ok) {
                                  // server failed to clear board
                                }
                              } catch (e) {
                                // error clearing board on server
                              }
                            }

                            // Clear local UI state
                            widget.controller.value.clear();
                            widget.controller.refresh();
                            setState(() {});
                          }
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

                            // Persist deletion on server if we have a board id and a saved instance id
                            try {
                              if (_currentBoardId != null && artefact.savedArtefactId != null) {
                                final success = await _boardLayoutService.deleteSavedArtefact(
                                  _currentBoardId!,
                                  artefact.savedArtefactId!,
                                );

                                if (!success) {
                                  // failed to delete saved artefact on server
                                }
                              }
                            } catch (e) {
                              // error while deleting saved artefact on server
                            }

                            // Remove from the local controller (this updates the UI)
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