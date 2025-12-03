import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/services/board_layout_service.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/ui/widgets/board/linear_board.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/singletons/token.dart';

typedef VoidCallback = void Function();

class RemoteArtifactBoardController {
  final ArtifactBoardController base;
  final String sessionId;
  final bool isOwner;
  final VoidCallback notifyView;
  final SettingsController settingsController;
  final BoardLayoutService _boardLayoutService;
  final String sharedBoardId; // ID of the board to load from backend
  
  // Debouncing timers for optimized updates
  Timer? _positionUpdateTimer;
  Timer? _sizeUpdateTimer;
  Timer? _layoutChangeTimer;
  final Map<String, Timer?> _artifactUpdateTimers = {};
  
  // Track artifact size listeners to avoid duplicates
  final Map<String, VoidCallback> _sizeListeners = {};

  RemoteArtifactBoardController({
    required this.sessionId,
    required this.notifyView,
    required this.settingsController,
    required this.isOwner,
    required this.sharedBoardId, // Required: board ID to load from backend
    ArtifactBoardController? existingController,
    BoardLayoutService? boardLayoutService,
  })  : base = existingController ??
            ArtifactBoardController(
                notifyView: notifyView, settingsController: settingsController),
        _boardLayoutService = boardLayoutService ?? BoardLayoutService() {
    // Register all delta update handlers
    SignalRService().onBoardUpdated = _handleRemoteUpdate;
    SignalRService().onArtifactAdded = _handleArtifactAdded;
    SignalRService().onArtifactRemoved = _handleArtifactRemoved;
    SignalRService().onArtifactMoved = _handleArtifactMoved;
    SignalRService().onArtifactResized = _handleArtifactResized;
    SignalRService().onLayoutChanged = _handleLayoutChanged;

    debugPrint(
        "RemoteSync => Initializing (isOwner=$isOwner, sessionId=$sessionId, sharedBoardId=$sharedBoardId)");
    debugPrint(
        "RemoteSync => SignalR connected: ${SignalRService().isConnected}");

    // Disable auto-save during remote sessions
    _setupRemoteSession();

    if (isOwner) {
      // Owner: send current board state to remote participant
      debugPrint("RemoteSync => Owner sending current board state");
      Future.delayed(const Duration(milliseconds: 200), () {
        _pushFullBoard();
      });
    } else {
      // Non-owner: wait for board state from owner via SignalR
      debugPrint("RemoteSync => Non-owner waiting for board state from owner");
      // Don't try to load from backend - just wait for SignalR updates
    }
  }

  void dispose() {
    // Cancel all debounce timers
    _positionUpdateTimer?.cancel();
    _sizeUpdateTimer?.cancel();
    _layoutChangeTimer?.cancel();
    for (var timer in _artifactUpdateTimers.values) {
      timer?.cancel();
    }
    _artifactUpdateTimers.clear();
    
    // Remove all size listeners
    _sizeListeners.clear();
    
    // Re-enable auto-save when leaving remote session
    _cleanupRemoteSession();
    
    if (SignalRService().onBoardUpdated == _handleRemoteUpdate) {
      SignalRService().onBoardUpdated = null;
    }
    if (SignalRService().onArtifactAdded == _handleArtifactAdded) {
      SignalRService().onArtifactAdded = null;
    }
    if (SignalRService().onArtifactRemoved == _handleArtifactRemoved) {
      SignalRService().onArtifactRemoved = null;
    }
    if (SignalRService().onArtifactMoved == _handleArtifactMoved) {
      SignalRService().onArtifactMoved = null;
    }
    if (SignalRService().onArtifactResized == _handleArtifactResized) {
      SignalRService().onArtifactResized = null;
    }
    if (SignalRService().onLayoutChanged == _handleLayoutChanged) {
      SignalRService().onLayoutChanged = null;
    }
    base.dispose();
  }

  bool get showDirectional => base.showDirectional;
  TalkingMat? get talkingMat => base.talkingMat;
  
  // Create a custom LinearBoard with the onArtifactRemoved callback for owner
  LinearBoard? get linearBoard {
    if (isOwner) {
      return LinearBoard(
        linearBoardController: base.linearBoardController,
        onArtifactRemoved: (artifact) {
          removeArtifact(artifact);
        },
      );
    }
    return base.linearBoard;
  }

  // ---------------- UI actions (owner syncs changes) ----------------

  void addArtifact(BoardArtefact artefact) {
    if (!isOwner) {
      debugPrint("RemoteSync => Non-owner cannot add artifacts");
      return;
    }

    // Listen to size changes with debouncing
    if (!_sizeListeners.containsKey(artefact.artefactId)) {
      final listener = () {
        if (isOwner) {
          _debouncedSizeUpdate(artefact);
        }
      };
      _sizeListeners[artefact.artefactId] = listener;
      artefact.sizeNotifier.addListener(listener);
    }

    base.addArtifactToCurrentBoard(artefact);
    notifyView();
    
    // Send delta update for added artifact
    _pushArtifactAdded(artefact);
  }

  void removeArtifact(BoardArtefact artefact) {
    if (!isOwner) {
      debugPrint("RemoteSync => Non-owner cannot remove artifacts");
      return;
    }

    // Remove size listener
    final listener = _sizeListeners.remove(artefact.artefactId);
    if (listener != null) {
      artefact.sizeNotifier.removeListener(listener);
    }

    if (base.showDirectional) {
      final index = base.linearBoardController.artifacts.indexOf(artefact);
      if (index != -1) {
        base.linearBoardController.removeArtifact(index);
      }
    } else {
      base.talkingmatController.removeArtifact(artefact);
    }

    notifyView();
    
    // Send delta update for removed artifact
    _pushArtifactRemoved(artefact.artefactId);
    debugPrint("RemoteSync => Artifact removed: ${artefact.artefactId}");
  }

  void switchBoard() {
    if (!isOwner) {
      debugPrint("RemoteSync => Non-owner cannot switch board");
      return;
    }

    base.switchCurrentBoard();
    notifyView();
    
    // Debounce layout change updates to prevent rapid toggles
    _layoutChangeTimer?.cancel();
    _layoutChangeTimer = Timer(const Duration(milliseconds: 300), () {
      _pushLayoutChanged();
    });
  }

  /// Called when an artifact position changes (from drag)
  void onArtifactPositionChanged(BoardArtefact artifact) {
    if (!isOwner) {
      debugPrint("RemoteSync => Non-owner cannot move artifacts");
      return;
    }

    // Debounce position updates during drag
    _debouncedPositionUpdate(artifact);
  }

  // ---------------- Build snapshot ----------------

  Map<String, dynamic> _buildBoardSnapshot() {
    final List<BoardArtefact> list = [];

    if (base.showDirectional) {
      for (final item in base.linearBoardController.artifacts) {
        if (item != null) list.add(item);
      }
    } else {
      list.addAll(base.talkingmatController.value);
    }

    return {
      'sessionId': sessionId,
      'layout': base.showDirectional ? 'linear' : 'talkingmat',
      'items': list.map((a) {
        final size = a.sizeNotifier.value;
        return {
          'id': a.artefactId,
          'name': a.baseArtefact?.name,
          'imageUrl': a.baseArtefact?.imageUrl,
          'soundUrl': a.baseArtefact?.soundUrl,
          'size': {'width': size.width, 'height': size.height},
          if (a.position != null)
            'position': {'dx': a.position!.dx, 'dy': a.position!.dy},
        };
      }).toList(),
    };
  }

  // ---------------- Debounced update methods ----------------

  void _debouncedPositionUpdate(BoardArtefact artifact) {
    // Cancel existing timer for this artifact
    _artifactUpdateTimers[artifact.artefactId]?.cancel();
    
    // Create new debounced timer (100ms delay)
    _artifactUpdateTimers[artifact.artefactId] = Timer(const Duration(milliseconds: 100), () {
      debugPrint("RemoteSync => Artifact moved: ${artifact.artefactId} to ${artifact.position}");
      _pushArtifactMoved(artifact);
    });
  }

  void _debouncedSizeUpdate(BoardArtefact artifact) {
    // Cancel existing timer for this artifact
    _artifactUpdateTimers['size_${artifact.artefactId}']?.cancel();
    
    // Create new debounced timer (100ms delay)
    _artifactUpdateTimers['size_${artifact.artefactId}'] = Timer(const Duration(milliseconds: 100), () {
      debugPrint("RemoteSync => Artifact resized: ${artifact.artefactId}");
      _pushArtifactResized(artifact);
    });
  }

  // ---------------- Delta update push methods ----------------

  Future<void> _pushArtifactAdded(BoardArtefact artifact) async {
    if (!SignalRService().isConnected) return;

    final size = artifact.sizeNotifier.value;
    final payload = {
      'sessionId': sessionId,
      'artifact': {
        'id': artifact.artefactId,
        'name': artifact.baseArtefact?.name,
        'imageUrl': artifact.baseArtefact?.imageUrl,
        'soundUrl': artifact.baseArtefact?.soundUrl,
        'size': {'width': size.width, 'height': size.height},
        if (artifact.position != null)
          'position': {'dx': artifact.position!.dx, 'dy': artifact.position!.dy},
      },
    };

    try {
      await SignalRService().sendArtifactAdded(payload);
      debugPrint("RemoteSync => Pushed artifact added: ${artifact.artefactId}");
    } catch (e) {
      debugPrint("RemoteSync => Failed to push artifact added: $e");
    }
  }

  Future<void> _pushArtifactRemoved(String artifactId) async {
    if (!SignalRService().isConnected) return;

    final payload = {
      'sessionId': sessionId,
      'artifactId': artifactId,
    };

    try {
      await SignalRService().sendArtifactRemoved(payload);
      debugPrint("RemoteSync => Pushed artifact removed: $artifactId");
    } catch (e) {
      debugPrint("RemoteSync => Failed to push artifact removed: $e");
    }
  }

  Future<void> _pushArtifactMoved(BoardArtefact artifact) async {
    if (!SignalRService().isConnected) return;
    if (artifact.position == null) return;

    final payload = {
      'sessionId': sessionId,
      'artifactId': artifact.artefactId,
      'position': {'dx': artifact.position!.dx, 'dy': artifact.position!.dy},
    };

    try {
      await SignalRService().sendArtifactMoved(payload);
      debugPrint("RemoteSync => Pushed artifact moved: ${artifact.artefactId}");
    } catch (e) {
      debugPrint("RemoteSync => Failed to push artifact moved: $e");
    }
  }

  Future<void> _pushArtifactResized(BoardArtefact artifact) async {
    if (!SignalRService().isConnected) return;

    final size = artifact.sizeNotifier.value;
    final payload = {
      'sessionId': sessionId,
      'artifactId': artifact.artefactId,
      'size': {'width': size.width, 'height': size.height},
    };

    try {
      await SignalRService().sendArtifactResized(payload);
      debugPrint("RemoteSync => Pushed artifact resized: ${artifact.artefactId}");
    } catch (e) {
      debugPrint("RemoteSync => Failed to push artifact resized: $e");
    }
  }

  Future<void> _pushLayoutChanged() async {
    if (!SignalRService().isConnected) return;

    final payload = {
      'sessionId': sessionId,
      'layout': base.showDirectional ? 'linear' : 'talkingmat',
    };

    try {
      await SignalRService().sendLayoutChanged(payload);
      debugPrint("RemoteSync => Pushed layout changed: ${payload['layout']}");
    } catch (e) {
      debugPrint("RemoteSync => Failed to push layout changed: $e");
    }
  }

  Future<void> _pushFullBoard() async {
    debugPrint("RemoteSync => _pushFullBoard called");
    debugPrint(
        "RemoteSync => SignalR state: ${SignalRService().isConnected ? 'CONNECTED' : 'DISCONNECTED'}");
    debugPrint("RemoteSync => SessionId: $sessionId");

    if (!SignalRService().isConnected) {
      debugPrint("RemoteSync => ERROR: Not connected, skipping push");
      return;
    }

    final payload = _buildBoardSnapshot();
    debugPrint(
        "RemoteSync => Built snapshot: ${payload['items'].length} items");

    try {
      await SignalRService().updateBoard(payload);
      debugPrint(
          "RemoteSync => SUCCESS: Pushed board (${payload['items'].length} items, layout=${payload['layout']})");
    } catch (e) {
      debugPrint("RemoteSync => EXCEPTION: Push failed: $e");
      rethrow;
    }
  }

  // ---------------- Receive remote updates ----------------

  void _handleRemoteUpdate(dynamic data) {
    if (data is! Map) {
      debugPrint("RemoteSync => Invalid data type: ${data.runtimeType}");
      return;
    }

    if (isOwner) {
      debugPrint("RemoteSync => Owner ignoring remote update");
      return;
    }

    final map = data.cast<String, dynamic>();
    final incomingSessionId = map['sessionId'] as String?;

    if (incomingSessionId != sessionId) {
      debugPrint(
          "RemoteSync => Ignoring update for different session: $incomingSessionId vs $sessionId");
      return;
    }

    final layout = map['layout'] as String?;
    final items = (map['items'] as List?) ?? [];

    debugPrint(
        "RemoteSync => Received update: layout=$layout, items=${items.length}");

    // Force layout to match sender (don't toggle, just set it)
    final directional = (layout == 'linear');
    if (base.showDirectional != directional) {
      debugPrint(
          "RemoteSync => Switching layout from ${base.showDirectional ? 'linear' : 'talking mat'} to ${directional ? 'linear' : 'talking mat'}");
      base.switchCurrentBoard();
    }

    // Get current artifacts
    final currentArtifacts = base.showDirectional
        ? base.linearBoardController.artifacts.whereType<BoardArtefact>().toList()
        : base.talkingmatController.value;

    // Create a map of current artifacts by ID
    final artifactMap = <String, BoardArtefact>{};
    for (final artifact in currentArtifacts) {
      if (artifact.artefactId.isNotEmpty) {
        artifactMap[artifact.artefactId] = artifact;
      }
    }

    // Track which artifact IDs we've seen in the update
    final updatedIds = <String>{};

    // Update or add artifacts
    for (final item in items) {
      if (item is! Map) continue;

      final id = item['id'] as String?;
      if (id == null) continue;

      updatedIds.add(id);

      final existing = artifactMap[id];
      if (existing != null) {
        // Update existing artifact position/size
        final size = item['size'];
        if (size != null) {
          existing.sizeNotifier.value = Size(
            (size['width'] as num).toDouble(),
            (size['height'] as num).toDouble(),
          );
        }

        final pos = item['position'];
        if (pos != null) {
          existing.position = Offset(
            (pos['dx'] as num).toDouble(),
            (pos['dy'] as num).toDouble(),
          );
        }
      } else {
        // Create new artifact
        final artefact = Artefact(
          artefactId: id,
          name: item['name'],
          imageUrl: item['imageUrl'],
          soundUrl: item['soundUrl'],
        );

        // Build headers for network image authentication
        final token = GetIt.instance.get<Token>().value;
        Map<String, String>? headers;
        if (token != null) headers = {'Authorization': 'Bearer $token'};

        final boardItem = BoardArtefact.fromArtefact(artefact, headers: headers);

        final size = item['size'];
        if (size != null) {
          boardItem.sizeNotifier.value = Size(
            (size['width'] as num).toDouble(),
            (size['height'] as num).toDouble(),
          );
        }

        final pos = item['position'];
        if (pos != null) {
          boardItem.position = Offset(
            (pos['dx'] as num).toDouble(),
            (pos['dy'] as num).toDouble(),
          );
        }

        base.addArtifactToCurrentBoard(boardItem);
      }
    }

    // Remove artifacts that weren't in the update
    if (base.showDirectional) {
      for (int i = base.linearBoardController.artifacts.length - 1; i >= 0; i--) {
        final artifact = base.linearBoardController.artifacts[i];
        if (artifact != null && !updatedIds.contains(artifact.artefactId)) {
          base.linearBoardController.removeArtifact(i);
        }
      }
    } else {
      base.talkingmatController.value.removeWhere(
        (artifact) => !updatedIds.contains(artifact.artefactId)
      );
    }

    notifyView();
    debugPrint("RemoteSync => Board updated with ${items.length} items");
  }

  // ---------------- Delta update handlers ----------------

  void _handleArtifactAdded(dynamic data) {
    if (data is! Map) return;
    if (isOwner) return;

    final map = data.cast<String, dynamic>();
    final incomingSessionId = map['sessionId'] as String?;
    if (incomingSessionId != sessionId) return;

    final artifactData = map['artifact'];
    if (artifactData == null) return;

    final id = artifactData['id'] as String?;
    if (id == null) return;

    debugPrint("RemoteSync => Received artifact added: $id");

    // Create new artifact
    final artefact = Artefact(
      artefactId: id,
      name: artifactData['name'],
      imageUrl: artifactData['imageUrl'],
      soundUrl: artifactData['soundUrl'],
    );

    final token = GetIt.instance.get<Token>().value;
    Map<String, String>? headers;
    if (token != null) headers = {'Authorization': 'Bearer $token'};

    final boardItem = BoardArtefact.fromArtefact(artefact, headers: headers);

    final size = artifactData['size'];
    if (size != null) {
      boardItem.sizeNotifier.value = Size(
        (size['width'] as num).toDouble(),
        (size['height'] as num).toDouble(),
      );
    }

    final pos = artifactData['position'];
    if (pos != null) {
      boardItem.position = Offset(
        (pos['dx'] as num).toDouble(),
        (pos['dy'] as num).toDouble(),
      );
    }

    base.addArtifactToCurrentBoard(boardItem);
    notifyView();
  }

  void _handleArtifactRemoved(dynamic data) {
    if (data is! Map) return;
    if (isOwner) return;

    final map = data.cast<String, dynamic>();
    final incomingSessionId = map['sessionId'] as String?;
    if (incomingSessionId != sessionId) return;

    final artifactId = map['artifactId'] as String?;
    if (artifactId == null) return;

    debugPrint("RemoteSync => Received artifact removed: $artifactId");

    // Find and remove the artifact
    if (base.showDirectional) {
      final artifacts = base.linearBoardController.artifacts;
      for (int i = artifacts.length - 1; i >= 0; i--) {
        final artifact = artifacts[i];
        if (artifact?.artefactId == artifactId) {
          base.linearBoardController.removeArtifact(i);
          debugPrint("RemoteSync => Removed artifact from linear board at index $i");
          notifyView();
          return;
        }
      }
    } else {
      final artifacts = base.talkingmatController.value;
      final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
        (a) => a?.artefactId == artifactId,
        orElse: () => null,
      );
      if (artifact != null) {
        base.talkingmatController.removeArtifact(artifact);
        debugPrint("RemoteSync => Removed artifact from talking mat");
        notifyView();
        return;
      }
    }
    debugPrint("RemoteSync => Artifact $artifactId not found for removal");
  }

  void _handleArtifactMoved(dynamic data) {
    if (data is! Map) return;
    if (isOwner) return;

    final map = data.cast<String, dynamic>();
    final incomingSessionId = map['sessionId'] as String?;
    if (incomingSessionId != sessionId) return;

    final artifactId = map['artifactId'] as String?;
    final position = map['position'];
    if (artifactId == null || position == null) return;

    debugPrint("RemoteSync => Received artifact moved: $artifactId to (${position['dx']}, ${position['dy']})");

    // Find the artifact and update its position
    if (base.showDirectional) {
      // Linear board - just update position
      final artifacts = base.linearBoardController.artifacts.whereType<BoardArtefact>().toList();
      final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
        (a) => a?.artefactId == artifactId,
        orElse: () => null,
      );
      
      if (artifact != null) {
        artifact.position = Offset(
          (position['dx'] as num).toDouble(),
          (position['dy'] as num).toDouble(),
        );
        debugPrint("RemoteSync => Updated artifact position on linear board");
        notifyView();
      } else {
        debugPrint("RemoteSync => Artifact $artifactId not found for move");
      }
    } else {
      // TalkingMat - need to trigger ValueNotifier by reassigning
      final artifacts = base.talkingmatController.value;
      final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
        (a) => a?.artefactId == artifactId,
        orElse: () => null,
      );
      
      if (artifact != null) {
        artifact.position = Offset(
          (position['dx'] as num).toDouble(),
          (position['dy'] as num).toDouble(),
        );
        // Trigger ValueNotifier by reassigning the list
        base.talkingmatController.value = List.from(artifacts);
        debugPrint("RemoteSync => Updated artifact position on talking mat");
        notifyView();
      } else {
        debugPrint("RemoteSync => Artifact $artifactId not found for move");
      }
    }
  }

  void _handleArtifactResized(dynamic data) {
    if (data is! Map) return;
    if (isOwner) return;

    final map = data.cast<String, dynamic>();
    final incomingSessionId = map['sessionId'] as String?;
    if (incomingSessionId != sessionId) return;

    final artifactId = map['artifactId'] as String?;
    final size = map['size'];
    if (artifactId == null || size == null) return;

    debugPrint("RemoteSync => Received artifact resized: $artifactId to ${size['width']}x${size['height']}");

    // Find the artifact and update its size
    if (base.showDirectional) {
      // Linear board
      final artifacts = base.linearBoardController.artifacts.whereType<BoardArtefact>().toList();
      final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
        (a) => a?.artefactId == artifactId,
        orElse: () => null,
      );

      if (artifact != null) {
        artifact.sizeNotifier.value = Size(
          (size['width'] as num).toDouble(),
          (size['height'] as num).toDouble(),
        );
        debugPrint("RemoteSync => Updated artifact size on linear board");
        notifyView();
      } else {
        debugPrint("RemoteSync => Artifact $artifactId not found for resize");
      }
    } else {
      // TalkingMat
      final artifacts = base.talkingmatController.value;
      final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
        (a) => a?.artefactId == artifactId,
        orElse: () => null,
      );

      if (artifact != null) {
        artifact.sizeNotifier.value = Size(
          (size['width'] as num).toDouble(),
          (size['height'] as num).toDouble(),
        );
        // Size has its own notifier, but trigger list update just in case
        base.talkingmatController.value = List.from(artifacts);
        debugPrint("RemoteSync => Updated artifact size on talking mat");
        notifyView();
      } else {
        debugPrint("RemoteSync => Artifact $artifactId not found for resize");
      }
    }
  }

  void _handleLayoutChanged(dynamic data) {
    if (data is! Map) return;
    if (isOwner) return;

    final map = data.cast<String, dynamic>();
    final incomingSessionId = map['sessionId'] as String?;
    if (incomingSessionId != sessionId) return;

    final layout = map['layout'] as String?;
    if (layout == null) return;

    debugPrint("RemoteSync => Received layout changed: $layout (current: ${base.showDirectional ? 'linear' : 'talkingmat'})");

    final directional = (layout == 'linear');
    if (base.showDirectional != directional) {
      debugPrint("RemoteSync => Switching board layout");
      base.switchCurrentBoard();
      notifyView();
    } else {
      debugPrint("RemoteSync => Already on correct layout");
    }
  }

  // ---------------- Remote session management ----------------

  void _setupRemoteSession() {
    // Wait for TalkingMat widget to be built
    Future.delayed(const Duration(milliseconds: 100), () {
      if (base.talkingMatKey.currentState != null) {
        base.talkingMatKey.currentState!.setRemoteSession(true);
        debugPrint("RemoteSync => Disabled auto-save for remote session");
      }
    });
  }

  void _cleanupRemoteSession() {
    if (base.talkingMatKey.currentState != null) {
      base.talkingMatKey.currentState!.setRemoteSession(false);
      debugPrint("RemoteSync => Re-enabled auto-save after remote session");
    }
  }

  // ---------------- Load board from backend ----------------
  // NOTE: This functionality is currently disabled during remote sessions.
  // Owner uses their existing board and sends it via SignalR.
  // Non-owner receives updates via SignalR only.
  //
  // Future implementation could use this to allow owner to load a saved board
  // at the start of a remote session.
  
  /* COMMENTED OUT - Not used in current remote session flow
  Future<void> _loadBoardFromBackend(String boardId) async {
    try {
      debugPrint("RemoteSync => Fetching board $boardId from backend...");
      final boardLayout = await _boardLayoutService.getBoard(boardId);

      if (boardLayout == null) {
        debugPrint("RemoteSync => ERROR: Failed to load board $boardId");
        return;
      }

      debugPrint("RemoteSync => Loaded board: ${boardLayout.name} with ${boardLayout.artefacts.length} artefacts");

      // Clear the current board
      _clearBoard();

      // Determine the board type based on saved positions
      // If positions are non-zero, assume TalkingMat, otherwise LinearBoard
      final hasTalkingMatPositions = boardLayout.artefacts.any((a) => a.posX != 0 || a.posY != 0);
      
      if (hasTalkingMatPositions && base.showDirectional) {
        // Switch to TalkingMat mode
        debugPrint("RemoteSync => Switching to TalkingMat mode");
        base.switchCurrentBoard();
      } else if (!hasTalkingMatPositions && !base.showDirectional) {
        // Switch to LinearBoard mode
        debugPrint("RemoteSync => Switching to LinearBoard mode");
        base.switchCurrentBoard();
      }

      // Add artifacts to the board
      for (final savedArtefact in boardLayout.artefacts) {
        final artefact = Artefact(
          artefactId: savedArtefact.artefactId,
          name: '', // You may need to fetch full artefact details from another endpoint
          imageUrl: null,
          soundUrl: null,
        );

        // Build headers for network image authentication
        final token = GetIt.instance.get<Token>().value;
        Map<String, String>? headers;
        if (token != null) headers = {'Authorization': 'Bearer $token'};

        final boardItem = BoardArtefact.fromArtefact(artefact, headers: headers);

        // Set size
        boardItem.sizeNotifier.value = Size(
          savedArtefact.width,
          savedArtefact.height,
        );

        // Set position (for TalkingMat)
        boardItem.position = Offset(
          savedArtefact.posX,
          savedArtefact.posY,
        );

        base.addArtifactToCurrentBoard(boardItem);
      }

      notifyView();
      debugPrint("RemoteSync => Board loaded successfully with ${boardLayout.artefacts.length} artefacts");

      // If owner, push the loaded board to other participants
      if (isOwner) {
        await Future.delayed(const Duration(milliseconds: 100));
        _pushFullBoard();
      }
    } catch (e) {
      debugPrint("RemoteSync => EXCEPTION loading board: $e");
    }
  }
  */
}
