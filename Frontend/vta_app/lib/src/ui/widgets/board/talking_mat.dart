// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:vta_app/src/controllers/talkingmat_controller.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/models/board_layout.dart';
import 'package:vta_app/src/services/board_layout_service.dart';
import 'package:vta_app/src/utilities/data/data_repository.dart';
import 'board_artifact.dart';
import '_long_press_option_wheel.dart';

typedef OnArtifactPositionChanged = void Function(BoardArtefact artifact);
typedef OnArtifactRemoved = void Function(BoardArtefact artifact);
typedef OnBoardLoaded = void Function();

class TalkingMat extends StatefulWidget {
  final List<BoardArtefact>? artifacts;
  final TalkingmatController controller;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final OnArtifactPositionChanged? onArtifactPositionChanged;
  final OnArtifactRemoved? onArtifactRemoved;
  final OnBoardLoaded? onBoardLoaded;
  final bool readOnly;

  TalkingMat({
    super.key,
    this.artifacts,
    required TalkingmatController controller,
    this.width,
    this.height,
    this.backgroundColor,
    this.onArtifactPositionChanged,
    this.onArtifactRemoved,
    this.onBoardLoaded,
    this.readOnly = false,
  }) : controller = controller;

  @override
  createState() => TalkingMatState();
}

class TalkingMatState extends State<TalkingMat>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late List<BoardArtefact> artifacts;
  final Expando<int> _zOrder = Expando<int>('z');
  int _zTick = 0;
  bool isGestureInsideMat = false;
  bool _isDraggingOverTrashCan = false;
  bool _isHoveringTrashCan = false;
  bool _isPlayingAllSounds = false;
  BoardArtefact? _draggedArtifactBeingDeleted;
  // Track if any artifact is currently being dragged to prevent size updates
  bool _isDragging = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final BoardLayoutService _boardLayoutService = BoardLayoutService();
  String? _currentBoardId; // Track the current board being edited

  // GlobalKeys for artifacts (using savedArtefactId or artefactId as key)
  final Map<String, GlobalKey> _artifactKeys = {};

  // Debounce timer for auto-save
  Timer? _saveTimer;

  // Flag to prevent auto-saving during certain operations
  Timer? _periodicSaveTimer;
  bool _inhibitAutoSave = false;

  // Track last saved state of each artefact layout to detect changes
  final Map<String, BoardArtefactLayout> _lastSavedLayouts = {};

  // Track local artefacts that haven't been matched to saved instances
  late List<BoardArtefact> unmatchedLocal;
  bool _isRemoteSession = false;
  bool _initialLoadComplete = false;
  final Set<String> _backendSavedArtefactIds =
      {}; // Track IDs that exist in backend

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    artifacts = widget.artifacts ?? [];
    unmatchedLocal = List.from(artifacts);

    _periodicSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (artifacts.isNotEmpty && !_inhibitAutoSave && _initialLoadComplete) {
        _autoSaveBoardLayout();
      }
    });

    _loadCurrentBoard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _saveTimer?.cancel();
    _periodicSaveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void setRemoteSession(bool isRemote) {
    _isRemoteSession = isRemote;
    if (isRemote) {
      // Cancel any pending saves and disable periodic saves
      _saveTimer?.cancel();
      _periodicSaveTimer?.cancel();
      _initialLoadComplete = true;
      debugPrint(
          "TalkingMat => Remote session mode enabled, auto-save disabled");
    } else {
      // Re-enable periodic saves
      _periodicSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (artifacts.isNotEmpty &&
            !_inhibitAutoSave &&
            !_isRemoteSession &&
            _initialLoadComplete) {
          _autoSaveBoardLayout();
        }
      });
      debugPrint(
          "TalkingMat => Remote session mode disabled, auto-save re-enabled");
    }
  }

  void addArtifact(BoardArtefact artifact) {
    setState(() {
      artifacts.add(artifact);
      artifact.sizeNotifier.addListener(() {
        _scheduleAutoSave();
      });
    });
    _immediateAutoSave();
  }

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
    _immediateAutoSave();
  }

  void removeAllArtifacts() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you want to remove all artifacts?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () {
                setState(() {
                  artifacts.clear();
                });
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop();
                _immediateAutoSave();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateArtifactPosition(BoardArtefact artifact, Offset offset) {
    Size artSize = artifact.renderedSize ?? const Size(200, 200);
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      debugPrint(
          '[TalkingMat] _updateArtifactPosition - renderBox is null, cannot update position');
      return;
    }

    // Convert the global touch/click position to local coordinates
    // This ensures the position is relative to the board's coordinate space
    final localPosition = renderBox.globalToLocal(offset);
    debugPrint(
        '[TalkingMat] _updateArtifactPosition - Local position: $localPosition');

    // Clamp the position to keep the artifact within bounds
    // Account for the artifact's own size to prevent it from going off-screen
    final double maxX = math.max(0.0, renderBox.size.width - artSize.width);
    final double maxY = math.max(0.0, renderBox.size.height - artSize.height);
    final clampedX = localPosition.dx.clamp(0.0, maxX);
    final clampedY = localPosition.dy.clamp(0.0, maxY);

    if (localPosition.dx != clampedX || localPosition.dy != clampedY) {
      debugPrint(
          '[TalkingMat] _updateArtifactPosition - Position clamped: (${localPosition.dx}, ${localPosition.dy}) -> ($clampedX, $clampedY)');
    }

    setState(() {
      artifact.position = Offset(clampedX, clampedY);
    });

    // Call sync callback if provided (for remote sessions)
    widget.onArtifactPositionChanged?.call(artifact);

    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (_inhibitAutoSave || _isRemoteSession || !_initialLoadComplete) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      _autoSaveBoardLayout();
    });
  }

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

  /// Public method to trigger auto-save (called by external controllers)
  void triggerAutoSave() {
    debugPrint("TalkingMat => triggerAutoSave called");
    _immediateAutoSave();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _immediateAutoSave();
        break;
      case AppLifecycleState.inactive:
        _scheduleAutoSave();
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }

  bool _hasLayoutChanged(BoardArtefactLayout layout) {
    final lastSaved =
        _lastSavedLayouts[layout.savedArtefactId ?? layout.artefactId];
    if (lastSaved == null) return true;

    return lastSaved.posX != layout.posX ||
        lastSaved.posY != layout.posY ||
        lastSaved.width != layout.width ||
        lastSaved.height != layout.height ||
        lastSaved.nameVisible != layout.nameVisible;
  }

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

  Future<void> _autoSaveBoardLayout() async {
    final layoutData = _getCurrentBoardLayout();
    if (layoutData.isEmpty) {
      return;
    }

    if (_currentBoardId == null) {
      await _createDefaultBoard();
      if (_currentBoardId == null) {
        return;
      }
    }

    debugPrint("TalkingMat => Saving to board: $_currentBoardId");

    try {
      final toPatch = layoutData
          .where((l) =>
              l.savedArtefactId != null &&
              _backendSavedArtefactIds.contains(l.savedArtefactId))
          .toList();
      final toCreate = layoutData
          .where((l) =>
              l.savedArtefactId == null ||
              !_backendSavedArtefactIds.contains(l.savedArtefactId))
          .toList();

      final toPatchChanged =
          toPatch.where((layout) => _hasLayoutChanged(layout)).toList();

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

        await _boardLayoutService.updateArtefactLayout(
            _currentBoardId!, request);
      }

      if (toCreate.isNotEmpty) {
        final saveRequest =
            SaveBoardRequest(name: 'Current Board', artefacts: layoutData);
        final updatedBoard = await _boardLayoutService.updateBoard(
            _currentBoardId!, saveRequest);
        if (updatedBoard != null) {
          try {
            _assignReturnedSavedIdsToLocal(updatedBoard.artefacts);
            // Track newly created savedArtefactIds from backend
            for (final layout in updatedBoard.artefacts) {
              if (layout.savedArtefactId != null) {
                _backendSavedArtefactIds.add(layout.savedArtefactId!);
              }
            }
            debugPrint(
                "TalkingMat => Now tracking ${_backendSavedArtefactIds.length} backend savedArtefactIds");
          } catch (e) {
            debugPrint(
                'TalkingMat => Error mapping returned saved ids after update: $e');
          }
        }
      }

      _updateLastSavedLayouts(layoutData);
    } catch (e) {
      // error auto-saving board layout
    }
  }

  Future<void> _loadCurrentBoard() async {
    try {
      final boards = await _boardLayoutService.getBoards();
      if (boards != null && boards.isNotEmpty) {
        final currentBoard = boards.firstWhere(
          (board) => board.name == 'Current Board',
          orElse: () => boards.first,
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
  Future<void> _restoreArtefactsFromBoard(
      BoardLayoutResponse boardLayout) async {
    try {
      debugPrint(
          "TalkingMat => Restoring ${boardLayout.artefacts.length} artifacts from board");
      final current = widget.controller.value;
      debugPrint(
          "TalkingMat => Current controller has ${current.length} artifacts");

      // Track all savedArtefactIds from backend
      _backendSavedArtefactIds.clear();
      for (final layout in boardLayout.artefacts) {
        if (layout.savedArtefactId != null) {
          _backendSavedArtefactIds.add(layout.savedArtefactId!);
        }
      }
      debugPrint(
          "TalkingMat => Tracked ${_backendSavedArtefactIds.length} backend savedArtefactIds");

      final unmatchedLocal = <BoardArtefact>[];
      unmatchedLocal.addAll(current);

      for (final artefactLayout in boardLayout.artefacts) {
        debugPrint(
            "TalkingMat => Processing artifact: ${artefactLayout.artefactId} (savedId: ${artefactLayout.savedArtefactId})");
        try {
          BoardArtefact? best;
          double bestDist = double.infinity;
          for (final local in unmatchedLocal) {
            if (local.baseArtefact?.artefactId == artefactLayout.artefactId) {
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
              best!.position = Offset(artefactLayout.posX, artefactLayout.posY);
              best.sizeNotifier.value =
                  Size(artefactLayout.width, artefactLayout.height);
              best.savedArtefactId = artefactLayout.savedArtefactId;
              // Restore per-instance name visibility if provided
              if (artefactLayout.nameVisible != null) {
                best.nameVisible = artefactLayout.nameVisible!;
              }
            });
            unmatchedLocal.remove(best);
            debugPrint(
                'TalkingMat => Matched existing local artifact ${artefactLayout.artefactId} to saved instance ${artefactLayout.savedArtefactId}');
          } else {
            await _addArtefactToBoard(
                artefactLayout.artefactId, artefactLayout);
          }
        } catch (e) {
          // error restoring artefact instance
        }
      }

      setState(() {});
    } finally {
      // Mark initial load as complete, allowing auto-save
      _initialLoadComplete = true;
      debugPrint(
          "TalkingMat => Initial board load complete, auto-save now enabled");

      // Notify listeners that board has finished loading
      widget.onBoardLoaded?.call();
    }
  }

  Future<void> _addArtefactToBoard(
      String artefactId, BoardArtefactLayout layout) async {
    try {
      final token = GetIt.instance.get<Token>();
      if (token.value == null) {
        debugPrint(
            'TalkingMat => No auth token available for fetching artifact');
        return;
      }

      final artifactRepository = ArtifactRepository();
      final artefact = await artifactRepository.fetchArtefact(artefactId,
          token: token.value!);

      if (artefact == null) {
        debugPrint(
            'TalkingMat => Could not fetch artifact $artefactId from API');
        return;
      }

      final boardArtefact = BoardArtefact.fromArtefact(
        artefact,
        headers: {'Authorization': 'Bearer ${token.value}'},
      );

      // Set the position and size from the saved layout
      boardArtefact.position = Offset(layout.posX, layout.posY);
      boardArtefact.sizeNotifier.value = Size(layout.width, layout.height);
      // Set the saved instance id so future updates target this specific instance
      boardArtefact.savedArtefactId = layout.savedArtefactId;

      widget.controller.addArtifact(boardArtefact);
    } catch (e) {
      // Silently handle artefact addition errors
    }
  }

  void _assignReturnedSavedIdsToLocal(List<BoardArtefactLayout> returned) {
    final current = widget.controller.value;
    final unmatchedLocal = <BoardArtefact>[...current];

    for (final artefactLayout in returned) {
      BoardArtefact? best;
      double bestDist = double.infinity;
      for (final local in unmatchedLocal) {
        if (local.baseArtefact?.artefactId == artefactLayout.artefactId &&
            local.savedArtefactId == null) {
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

    final layoutData = _getCurrentBoardLayout();
    _updateLastSavedLayouts(layoutData);
  }

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
        print(
            'Debug: Created default board "$defaultBoardName" with ID: ${response.boardId}');
        // Map returned saved artefact instance ids back onto the local artifacts by best-match

        try {
          _assignReturnedSavedIdsToLocal(response.artefacts);
        } catch (_) {
          // ignore mapping errors
        }
      }
    } catch (e) {
      // error creating default board
    }
  }

  List<BoardArtefactLayout> _getCurrentBoardLayout() {
    final currentArtifacts = widget.controller.value;

    final validArtifacts = currentArtifacts
        .where((artifact) =>
            artifact.baseArtefact != null &&
            artifact.baseArtefact!.artefactId != null)
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
        } catch (_) {
          // ignore mapping errors
        }

        return response.boardId;
      }
    } catch (e) {
      // error saving board
    }
    return null;
  }

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
            artifact.position =
                Offset(artefactLayout.posX, artefactLayout.posY);
            artifact.sizeNotifier.value =
                Size(artefactLayout.width, artefactLayout.height);
          });
        }

        // loaded board
        await _restoreArtefactsFromBoard(boardLayout);
        print(
            'Debug: Loaded board "${boardLayout.name}" with ${boardLayout.artefacts.length} artefacts');
      }
    } catch (e) {
      // error loading board
    }
  }

  Future<List<BoardLayoutResponse>?> getSavedBoards() async {
    try {
      return await _boardLayoutService.getBoards();
    } catch (e) {
      // error getting saved boards
      return null;
    }
  }

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
          debugPrint(
              '[TalkingMat] Artifact ID:$artifactId - Initial rendered size set: $size');
        } else {
          // Only update if the size difference is significant (> 50px) to avoid micro-adjustments
          // This prevents artifacts from constantly resizing when other artifacts are dragged
          final sizeDiff = (artifact.renderedSize!.width - size.width).abs();
          if (sizeDiff > 50.0) {
            debugPrint(
                '[TalkingMat] Artifact ID:$artifactId - Rendered size updated: ${artifact.renderedSize} -> $size');
            artifact.renderedSize = size;
          }
        }
      } else {
        // Don't log warnings if the context is null - this is normal when an artifact is being dragged
        // (childWhenDragging replaces the child, so the key context becomes null)
      }
    });
  }

  bool _isInsideMat(Offset globalOffset, {Size? artefactSize}) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    // Convert global offset to local coordinates
    final Offset localPos = renderBox.globalToLocal(globalOffset);
    final Size matSize = renderBox.size;

    // If artefactSize is provided, check if the artifact fits within bounds
    if (artefactSize != null) {
      final bool insideHoriz = localPos.dx >= 0 &&
          (localPos.dx + artefactSize.width) <= matSize.width;
      final bool insideVert = localPos.dy >= 0 &&
          (localPos.dy + artefactSize.height) <= matSize.height;
      return insideHoriz && insideVert;
    } else {
      // Just check if the point is inside the mat
      return localPos.dx >= 0 &&
          localPos.dx <= matSize.width &&
          localPos.dy >= 0 &&
          localPos.dy <= matSize.height;
    }
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
        debugPrint(
            '[TalkingMat] LayoutBuilder - Constraints: ${constraints.maxWidth.toInt()}x${constraints.maxHeight.toInt()}, Mat: ${matWidth.toInt()}x${matHeight.toInt()}');

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
                          // If readOnly mode, just display the artifact without interaction
                          if (widget.readOnly) {
                            return RepaintBoundary(
                              key: measurementKey,
                              child: IgnorePointer(
                                child: artefact.content,
                              ),
                            );
                          }
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
                            feedback: Opacity(
                              opacity: 0.7,
                              child: Transform.scale(
                                scale: 1.2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 216, 216, 216)
                                            .withOpacity(0.3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
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
                                _zOrder[artefact] =
                                    ++_zTick; // bring instance to front
                              });
                            },
                            onDragEnd: (details) {
                              // Don't update position if this artifact was deleted (dropped on trashcan)
                              if (_draggedArtifactBeingDeleted == artefact) {
                                _draggedArtifactBeingDeleted = null;
                                return;
                              }

                              final Size artSize =
                                  artefact.renderedSize ?? const Size(200, 200);
                              if (_isInsideMat(details.offset,
                                  artefactSize: artSize)) {
                                Offset adjustedPosition = details.offset;
                                if (artefact.nameVisible == true) {
                                  final double nameOffset =
                                      _getNameDisplayOffset(
                                    artefact.baseArtefact?.name ?? '',
                                    context,
                                  );
                                  adjustedPosition = Offset(
                                    details.offset.dx,
                                    details.offset.dy - nameOffset,
                                  );
                                }
                                _updateArtifactPosition(
                                    artefact, adjustedPosition);
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
                    // Trashcan positioned on top with higher z-index
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.lerp(
                                Alignment.bottomCenter, Alignment.center, 0.1) ??
                            Alignment.bottomCenter,
                        child: IgnorePointer(
                          ignoring: false,
                          child: GestureDetector(
                        onTap: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Slet alle artefakter'),
                                content: const Text(
                                    'Er du sikker på, at du vil slette alle artefakter på denne tavle?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: const Text('Annuller'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text('Slet'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldDelete == true) {
                            if (_currentBoardId != null) {
                              try {
                                final ok = await _boardLayoutService
                                    .deleteAllSavedArtefacts(_currentBoardId!);
                                if (!ok) {
                                  // server failed to clear board
                                  print(
                                      'Debug: Server failed to clear board $_currentBoardId');
                                }
                              } catch (e) {
                                // error clearing board on server
                                print(
                                    'Debug: Error clearing board on server: $e');
                              } finally {
                                _inhibitAutoSave = false;
                              }
                            }

                            widget.controller.value.clear();
                            widget.controller.refresh();
                            setState(() {});
                          }
                        },
                        child: DragTarget<BoardArtefact>(
                          builder: (context, data, rejectedData) {
                            return buildTrashCan(
                              height: _isDraggingOverTrashCan ? 90 : 50,
                              width: _isDraggingOverTrashCan ? 90 : 50,
                            );
                          },
                          onAcceptWithDetails: (details) async {
                            var artefact = details.data;

                            // Mark this artifact as being deleted to prevent onDragEnd from updating position
                            _draggedArtifactBeingDeleted = artefact;

                            // Persist deletion on server if we have a board id and a saved instance id
                            if (_currentBoardId != null &&
                                artefact.savedArtefactId != null) {
                              _inhibitAutoSave = true;
                              try {
                                await _boardLayoutService.deleteSavedArtefact(
                                  _currentBoardId!,
                                  artefact.savedArtefactId!,
                                );
                              } catch (e) {
                                debugPrint(
                                    'TalkingMat => Error deleting saved artefact on server: $e');
                              } finally {
                                _inhibitAutoSave = false;
                              }
                            }

                            // Handle Session-Artefact deletion
                            if (artefact.baseArtefact?.categoryId ==
                                'Session-Artefact') {
                              try {
                                final artefactController =
                                    GetIt.instance.get<ArtefactController>();
                                final deleted =
                                    await artefactController.deleteArtefact(
                                        context, artefact.baseArtefact!);
                                if (deleted) {
                                  widget.controller.removeArtifact(artefact);
                                  // Notify remote session if callback is provided
                                  widget.onArtifactRemoved?.call(artefact);
                                }
                              } catch (e) {
                                debugPrint(
                                    'TalkingMat => Failed to delete session artefact from server: $e');
                              }
                            } else {
                              // Remove from the local controller (this updates the UI)
                              widget.controller.removeArtifact(artefact);
                              // Notify remote session if callback is provided
                              widget.onArtifactRemoved?.call(artefact);
                            }

                            setState(() {
                              _isDraggingOverTrashCan = false;
                            });
                            _draggedArtifactBeingDeleted = null;
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
                    ),
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
