import 'package:flutter/material.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/talkingmat_controller.dart';
import 'package:vta_app/src/singletons/token.dart';
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

class TalkingMatState extends State<TalkingMat> with TickerProviderStateMixin, WidgetsBindingObserver {
  late List<BoardArtefact> artifacts;
  // z-order: attached per artefact instance (supports duplicates)
  final Expando<int> _zOrder = Expando<int>('z');
  final int _zTick = 0;
  bool isGestureInsideMat = false;
  bool _isDraggingOverTrashCan = false;
  bool _isHoveringTrashCan = false;
  bool _isPlayingAllSounds = false;
  // Track if any artifact is currently being dragged to prevent size updates
  bool _isDragging = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final BoardLayoutService _boardLayoutService = BoardLayoutService();
  String? _currentBoardId; // Track the current board being edited
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  
  // GlobalKeys for artifacts (using savedArtefactId or artefactId as key)
  final Map<String, GlobalKey> _artifactKeys = {};
  
  // Debounce timer for auto-save
  Timer? _saveTimer;
  // Periodic safety auto-save timer
  Timer? _periodicSaveTimer;
  // Inhibit auto-save while delete/clear operations are in progress to avoid races
  final bool _inhibitAutoSave = false;
  // Track last saved layout data to detect changes
  final Map<String, BoardArtefactLayout> _lastSavedLayouts = {};

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

    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Set up periodic safety auto-save every 30 seconds
    _periodicSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (artifacts.isNotEmpty && !_inhibitAutoSave) {
        _autoSaveBoardLayout();
      }
    });

    // Try to load the current board on initialization
    _loadCurrentBoard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    _saveTimer?.cancel();
    _periodicSaveTimer?.cancel();
    
    // Remove observer for app lifecycle changes
    WidgetsBinding.instance.removeObserver(this);
    
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
    
    // Auto-save immediately when a new artefact is added to the board
    _immediateAutoSave();
  }

  // Removes artefact by artefactId
  void removeArtifactById(String artefactId) {
    setState(() {
      artifacts.removeWhere((artifact) {
        final shouldRemove = artifact.artefactId == artefactId;
        if (shouldRemove) {
          // Clean up the GlobalKey for this artifact
          final keyId = artifact.savedArtefactId ?? 
                       '${artifact.baseArtefact?.artefactId ?? 'unknown'}_${artifact.hashCode}';
          _artifactKeys.remove(keyId);
        }
        return shouldRemove;
      });
    });
    
    // Auto-save when an artefact is removed
    _immediateAutoSave();
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
                
                // Auto-save when all artefacts are removed
                _immediateAutoSave();
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

      // Update the artifact's position directly on the artifact object
      artifact.position = newRelativePos;
      
      // Also notify the controller to trigger ValueListenableBuilder rebuild
      // Always update the controller value to ensure the change is reflected
      final currentList = List<BoardArtefact>.from(widget.controller.value);
      if (currentList.isEmpty) {
        debugPrint('[TalkingMat] _updateArtifactPosition: WARNING - Controller value is empty, cannot update position!');
        return;
      }
      
      // Find and update the artifact in the list
      final index = currentList.indexWhere((a) => 
        a.savedArtefactId == artifact.savedArtefactId || 
        (a.savedArtefactId == null && artifact.savedArtefactId == null && 
         a.baseArtefact?.artefactId == artifact.baseArtefact?.artefactId));
      
      if (index != -1) {
        // Update the artifact in the list (it's the same reference, so position is already updated)
        debugPrint('[TalkingMat] _updateArtifactPosition: Setting controller value with ${currentList.length} artifacts');
        widget.controller.value = currentList;
      } else {
        debugPrint('[TalkingMat] _updateArtifactPosition: WARNING - Artifact not found in controller value list!');
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
    // TODO: Implement play all sounds functionality
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
           lastSaved.height != layout.height;
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
        );

        final success = await _boardLayoutService.updateArtefactLayout(_currentBoardId!, request);
        // TODO: pause timer while resizing or dragging as they cause problems.
        /*
        if (!success) {
          print('Debug: Failed to auto-save layout for artefact ${artefactLayout.artefactId}');
        }
        */
      }

      // If there are artefacts without saved IDs, perform a full board update (PUT) to create them in one go
      if (toCreate.isNotEmpty) {
        final saveRequest = SaveBoardRequest(name: 'Current Board', artefacts: layoutData);
        final updatedBoard = await _boardLayoutService.updateBoard(_currentBoardId!, saveRequest);
        if (updatedBoard != null) {
          // Map returned saved IDs onto local instances
          try {
            _assignReturnedSavedIdsToLocal(updatedBoard.artefacts);
          } catch (e) {
            print('Debug: Error mapping returned saved ids after update: $e');
          }
        } else {
          print('Debug: Failed to update board to create missing artefact instances');
        }
      }

      // Update tracking after successful save
      _updateLastSavedLayouts(layoutData);
    } catch (e) {
      // Silently handle auto-save errors
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
        
        // Actually restore the board layout on startup
        await _restoreArtefactsFromBoard(currentBoard);
      }
    } catch (e) {
      // This is fine - a new board will be created when first needed
    }
  }

  /// Restore artefacts from a saved board layout
  Future<void> _restoreArtefactsFromBoard(BoardLayoutResponse boardLayout) async {
    // Try to match saved artefacts to existing local instances first (by artefactId + closest position)
  // Do NOT clear the controller here — we want to match against the current local instances
  final current = widget.controller.value;
    final unmatchedLocal = <BoardArtefact>[];
    unmatchedLocal.addAll(current);

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
          });
          // remove from unmatched list so we don't match it again
          unmatchedLocal.remove(best);
          print('Debug: Matched existing local artefact ${artefactLayout.artefactId} to saved instance ${artefactLayout.savedArtefactId}');
        } else {
          // No local match found: fetch and add a fresh instance
          await _addArtefactToBoard(artefactLayout.artefactId, artefactLayout);
        }
      } catch (e) {
        // Silently handle restoration errors
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
        print('Debug: No auth token available for fetching artefact');
        return;
      }

      // Fetch the artefact data from the API
      final artifactRepository = ArtifactRepository();
      final artefact = await artifactRepository.fetchArtefact(artefactId, token: token.value!);
      
      if (artefact == null) {
        print('Debug: Could not fetch artefact $artefactId from API');
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

      // Add it to the controller
      widget.controller.addArtifact(boardArtefact);
      
    } catch (e) {
      // Silently handle artefact addition errors
    }
  }

  /// Assign returned savedArtefactIds (from server) to local BoardArtefact instances by best-match
  void _assignReturnedSavedIdsToLocal(List<BoardArtefactLayout> returned) {
    final current = widget.controller.value;
    final unmatchedLocal = <BoardArtefact>[...current];

    for (final artefactLayout in returned) {
      BoardArtefact? best;
      double bestDist = double.infinity;
      for (final local in unmatchedLocal) {
        if (local.baseArtefact?.artefactId == artefactLayout.artefactId && local.savedArtefactId == null) {
          final localPos = local.position ?? Offset.zero;
          final dx = localPos.dx - artefactLayout.posX;
          final dy = localPos.dy - artefactLayout.posY;
          final dist = dx * dx + dy * dy;
          if (dist < bestDist) {
            bestDist = dist;
            best = local;
          }
        }
      }

      if (best != null) {
        setState(() {
          best!.savedArtefactId = artefactLayout.savedArtefactId;
        });
        unmatchedLocal.remove(best);
      }
    }
    
    // Update tracking after assigning saved IDs
    final layoutData = _getCurrentBoardLayout();
    _updateLastSavedLayouts(layoutData);
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
        print('Debug: Created default board "$defaultBoardName" with ID: ${response.boardId}');
        // Map returned saved artefact instance ids back onto the local artifacts by best-match
        try {
          _assignReturnedSavedIdsToLocal(response.artefacts);
        } catch (_) {
          // ignore mapping errors
        }
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
    
    final validArtifacts = currentArtifacts
        .where((artifact) => artifact.baseArtefact != null && artifact.baseArtefact!.artefactId != null)
        .map((artifact) {
      final position = artifact.position ?? Offset.zero;
      final size = artifact.sizeNotifier.value;

      return BoardArtefactLayout(
        savedArtefactId: artifact.savedArtefactId,
        artefactId: artifact.baseArtefact!.artefactId!,
        posX: position.dx,
        posY: position.dy,
        width: size.width,
        height: size.height,
      );
    }).toList();
    
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
        print('Debug: Saved board "$boardName" with ID: ${response.boardId}');
        // Map returned saved artefact instance ids back onto local artifacts by best-match
        try {
          _assignReturnedSavedIdsToLocal(response.artefacts);
        } catch (_) {}

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
        await _restoreArtefactsFromBoard(boardLayout);
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

  // Get or create a GlobalKey for an artifact
  GlobalKey _getArtifactKey(BoardArtefact artifact) {
    // Use a unique identifier that includes both artefactId and instance info
    final String keyId = artifact.savedArtefactId ?? 
                         '${artifact.baseArtefact?.artefactId ?? 'unknown'}_${artifact.hashCode}';
    return _artifactKeys.putIfAbsent(keyId, () => GlobalKey());
  }
  
  // Clean up GlobalKeys for artifacts that no longer exist
  void _cleanupArtifactKeys(List<BoardArtefact> currentArtifacts) {
    final Set<String> currentKeyIds = currentArtifacts.map((artifact) {
      return artifact.savedArtefactId ?? 
             '${artifact.baseArtefact?.artefactId ?? 'unknown'}_${artifact.hashCode}';
    }).toSet();
    
    // Remove keys for artifacts that no longer exist
    _artifactKeys.removeWhere((keyId, key) => !currentKeyIds.contains(keyId));
  }

  // Access the size of the artifact's content after it has been rendered
  void _loadArtifactSize(GlobalKey key, BoardArtefact artifact) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Don't update sizes while dragging - this prevents other artifacts from resizing
      if (_isDragging) {
        return;
      }
      
      final String artifactId = artifact.baseArtefact?.artefactId ?? 'unknown';
      
      final RenderBox? renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        
        // Only update if renderedSize is null (first time) or if the size has changed significantly
        // This prevents constant updates during drag operations that cause other artifacts to resize
        if (artifact.renderedSize == null) {
          artifact.renderedSize = size;
          debugPrint('[TalkingMat] Artifact ID:$artifactId - Initial rendered size set: $size');
        } else {
          // Only update if the size difference is significant (> 50px) to avoid micro-adjustments
          // This prevents artifacts from constantly resizing when other artifacts are dragged
          final sizeDiff = (artifact.renderedSize!.width - size.width).abs();
          if (sizeDiff > 50.0) {
            debugPrint('[TalkingMat] Artifact ID:$artifactId - Rendered size updated: ${artifact.renderedSize} -> $size');
            artifact.renderedSize = size;
          }
        }
      } else {
        // Don't log warnings if the context is null - this is normal when an artifact is being dragged
        // (childWhenDragging replaces the child, so the key context becomes null)
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
              
              // Clean up GlobalKeys for artifacts that no longer exist
              _cleanupArtifactKeys(artefacts);
              
              // Critical: Check if controller value is empty but we expect artifacts
              if (artefacts.isEmpty && widget.controller.value.isEmpty) {
                debugPrint('[TalkingMat] WARNING: Controller value is empty! This should not happen unless explicitly cleared.');
                debugPrint('[TalkingMat] Controller value identity: ${widget.controller.value.hashCode}, controller identity: ${widget.controller.hashCode}');
              } else if (artefacts.length != widget.controller.value.length) {
                debugPrint('[TalkingMat] WARNING: Mismatch! artefacts.length=${artefacts.length} but controller.value.length=${widget.controller.value.length}');
                debugPrint('[TalkingMat] ValueListenableBuilder received ${artefacts.length} but controller has ${widget.controller.value.length}');
              }
              
              // Build the stack directly - artifacts use relative positioning so they don't need key-based rebuilds
              return DragTarget<BoardArtefact>(
                onAcceptWithDetails: (details) {
                  // When an artifact is dropped on the mat, update its position
                  final artefact = details.data;
                  _updateArtifactPosition(artefact, details.offset);
                },
                onWillAcceptWithDetails: (details) {
                  return true; // Accept drops on the mat
                },
                builder: (context, candidateData, rejectedData) {
                  return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                    ...artefacts.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final BoardArtefact artefact = entry.value;
                      
                      // Get or create a key for this artifact
                      final GlobalKey artifactKey = _getArtifactKey(artefact);
                      _loadArtifactSize(artifactKey, artefact);
                      
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
                      double defaultArtifactSize = (matWidth < matHeight ? matWidth : matHeight) * 0.4;
                      defaultArtifactSize = defaultArtifactSize.clamp(200.0, 600.0);
                      
                      // Use renderedSize only if it's reasonable (not too small)
                      // If renderedSize is too small (< 150px), use the default instead
                      double artifactSize = artefact.renderedSize?.width ?? defaultArtifactSize;
                      if (artifactSize < 150.0) {
                        artifactSize = defaultArtifactSize;
                      }
                      debugPrint('[TalkingMat] Artifact[$index] ID:$artifactId - Size: renderedSize=${artefact.renderedSize}, default=$defaultArtifactSize, final=$artifactSize');
                      
                      // Ensure artifact size is reasonable relative to mat
                      artifactSize = artifactSize.clamp(150.0, matWidth * 0.6);
                      artifactSize = artifactSize.clamp(150.0, matHeight * 0.6);
                      
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
                        width: artifactSize,
                        height: artifactSize,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: artifactSize,
                            maxHeight: artifactSize,
                            minWidth: 50.0,
                            minHeight: 50.0,
                          ),
                          child: LongPressOptionWheel(
                            artifact: artefact,
                            controller: widget.controller,
                            artifactKey: artifactKey,
                            artifactController: GetIt.instance.get<ArtefactController>(),
                            child: Listener(
                              behavior: HitTestBehavior.translucent,
                              onPointerMove: (_) {
                                // Track drag when pointer moves (actual drag, not just press)
                                if (!_isDragging) {
                                  setState(() {
                                    _isDragging = true;
                                  });
                                }
                              },
                              onPointerUp: (_) {
                                // Track drag end - use a small delay to ensure drag has completed
                                Future.delayed(const Duration(milliseconds: 50), () {
                                  if (mounted) {
                                    setState(() {
                                      _isDragging = false;
                                    });
                                  }
                                });
                              },
                              onPointerCancel: (_) {
                                // Clear dragging state if pointer is cancelled
                                setState(() {
                                  _isDragging = false;
                                });
                              },
                              child: Draggable<BoardArtefact>(
                                data: artefact,
                                feedback: Transform.scale(
                                  scale: 1.2,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: artifactSize * 1.2,
                                      maxHeight: artifactSize * 1.2,
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
                                child: Container(key: artifactKey, child: artefact.content),
                                onDragEnd: (details) {
                                  // Clear dragging state
                                  setState(() {
                                    _isDragging = false;
                                  });
                                  if (_isInsideMat(details.offset)) {
                                    _updateArtifactPosition(artefact, details.offset);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                Align(
                  alignment: Alignment.lerp(
                          Alignment.bottomCenter, Alignment.center, 0.1) ??
                      Alignment.bottomCenter,
                  child: Builder(
                        builder: (context) {
                          // Use matWidth from LayoutBuilder instead of MediaQuery to avoid zoom issues
                          double screenWidth = matWidth;
                          double baseSize = screenWidth > 600 ? 50 : 35;
                          double expandedSize = screenWidth > 600 ? 120 : 80;
                          final size = _isDraggingOverTrashCan ? expandedSize : baseSize;
                          return DragTarget<BoardArtefact>(
                            builder: (context, data, rejectedData) {
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
                          );
                        },
                      ),
                ),

                      ],
                    );
                  },
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