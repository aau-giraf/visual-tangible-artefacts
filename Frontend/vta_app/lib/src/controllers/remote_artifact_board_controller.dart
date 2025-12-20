import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/ui/widgets/board/linear_board.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/platform_utils.dart';

typedef VoidCallback = void Function();

/// Fix localhost URLs to use the correct API URL for the current platform
String? _fixLocalhostUrl(String? url) {
  if (url == null || url.isEmpty) return url;
  
  // Replace localhost URLs with the platform-specific API URL
  if (url.contains('localhost:5192')) {
    final apiUrl = PlatformUtils.getApiUrl();
    // Remove '/api/' suffix from apiUrl if present to avoid doubling it
    final baseUrl = apiUrl.endsWith('/api/') ? apiUrl.substring(0, apiUrl.length - 5) : apiUrl;
    return url.replaceAll('http://localhost:5192', baseUrl);
  }
  
  return url;
}

// Generate a UUID v4 for savedArtefactId
// Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
String _generateSavedArtefactId() {
  final random = Random();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  
  // Set version to 4 (UUID v4)
  values[6] = (values[6] & 0x0f) | 0x40;
  // Set variant to RFC 4122
  values[8] = (values[8] & 0x3f) | 0x80;
  
  final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class RemoteArtifactBoardController {
  final ArtifactBoardController base;
  final String sessionId;
  final bool isOwner;
  final VoidCallback notifyView;
  final SettingsController settingsController;
  
  // Debouncing timers for optimized updates
  Timer? _positionUpdateTimer;
  Timer? _sizeUpdateTimer;
  Timer? _layoutChangeTimer;
  final Map<String, Timer?> _artifactUpdateTimers = {};
  
  // Track artifact size listeners to avoid duplicates
  final Map<String, VoidCallback> _sizeListeners = {};
  
  // Track number of artifacts to detect additions
  int _lastArtifactCount = 0;
  
  // Track field count to detect changes
  int _lastFieldCount = 0;

  RemoteArtifactBoardController({
    required this.sessionId,
    required this.notifyView,
    required this.settingsController,
    required this.isOwner,
    ArtifactBoardController? existingController,
  })  : base = existingController ??
            ArtifactBoardController(
                notifyView: notifyView, settingsController: settingsController) {
    // Register all delta update handlers
    SignalRService().onBoardUpdated = _handleRemoteUpdate;
    SignalRService().onArtifactAdded = _handleArtifactAdded;
    SignalRService().onArtifactRemoved = _handleArtifactRemoved;
    SignalRService().onArtifactMoved = _handleArtifactMoved;
    SignalRService().onArtifactResized = _handleArtifactResized;
    SignalRService().onLayoutChanged = _handleLayoutChanged;
    SignalRService().onFieldCountChanged = _handleFieldCountChanged;

    debugPrint(
        "RemoteSync => Initializing (isOwner=$isOwner, sessionId=$sessionId)");
    debugPrint(
        "RemoteSync => SignalR connected: ${SignalRService().isConnected}");

    // Disable auto-save during remote sessions
    _setupRemoteSession();

    if (isOwner) {
      _setupOwnerCallbacks();
      
      // Set up listener to detect artifact additions and trigger auto-save
      base.talkingmatController.addListener(_onControllerChanged);
      _lastArtifactCount = base.talkingmatController.value.length;
      
      // Set up listener to detect field count changes in linear board
      base.linearBoardController.addListener(_onLinearBoardChanged);
      _lastFieldCount = base.linearBoardController.fieldCount;
      
      // Board load callback will trigger _onOwnerBoardLoaded() when ready
      debugPrint("RemoteSync => Waiting for owner's board to load (callback-based)");
    } else {
      // Non-owner: clear existing artifacts and wait for board state from owner via SignalR
      debugPrint("RemoteSync => Non-owner clearing artifacts and waiting for board state from owner");
      _clearBoard();
    }
  }

  void dispose() {
    // Remove controller listener
    if (isOwner) {
      base.talkingmatController.removeListener(_onControllerChanged);
      base.linearBoardController.removeListener(_onLinearBoardChanged);
    }
    
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
    
    if (!isOwner) {
      base.dispose();
    }
  }

  bool get showDirectional => base.showDirectional;
  
  // Callbacks are set up via the remote controller's methods
  TalkingMat? get ownerTalkingMat {
    if (!isOwner || base.showDirectional) return null;
    return base.talkingMat;
  }
  
  // Create a read-only TalkingMat for non-owner
  TalkingMat? get talkingMat {
    if (isOwner) {
      return base.talkingMat;
    }
    return TalkingMat(
      controller: base.talkingmatController,
      readOnly: true,
    );
  }
  
  // Return the LinearBoard from base (configured in _setupOwnerCallbacks if owner)
  LinearBoard? get linearBoard => base.linearBoard;

  // ---------------- UI actions (owner syncs changes) ----------------

  void addArtifact(BoardArtefact artefact) {
    if (!isOwner) {
      debugPrint("RemoteSync => Non-owner cannot add artifacts");
      return;
    }

    // Generate savedArtefactId for newly added artifacts
    if (artefact.savedArtefactId == null) {
      artefact.savedArtefactId = _generateSavedArtefactId();
      debugPrint("RemoteSync => Generated savedArtefactId for new artifact: ${artefact.savedArtefactId}");
    }

    // Listen to size changes with debouncing
    if (!_sizeListeners.containsKey(artefact.savedArtefactId)) {
      void listener() {
        if (isOwner) {
          debugPrint("RemoteSync => Size listener triggered for ${artefact.savedArtefactId}");
          _debouncedSizeUpdate(artefact);
        }
      }
      _sizeListeners[artefact.savedArtefactId!] = listener;
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
    if (artefact.savedArtefactId != null) {
      final listener = _sizeListeners.remove(artefact.savedArtefactId);
      if (listener != null) {
        artefact.sizeNotifier.removeListener(listener);
      }
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
    if (artefact.savedArtefactId != null) {
      _pushArtifactRemoved(artefact.savedArtefactId!);
      debugPrint("RemoteSync => Artifact removed: ${artefact.savedArtefactId}");
    }
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
      // Send full board snapshot after layout change to ensure sync
      Future.delayed(const Duration(milliseconds: 100), () {
        _pushFullBoard();
      });
    });
  }

  /// Called when an artifact position changes (from drag)
  void onArtifactPositionChanged(BoardArtefact artifact) {
    if (!isOwner) {
      debugPrint("RemoteSync => Non-owner cannot move artifacts");
      return;
    }

    final savedId = artifact.savedArtefactId;
    if (savedId == null) {
      debugPrint("RemoteSync => WARNING: Artifact moved but has no savedArtefactId");
      return;
    }
    
    debugPrint(
        "RemoteSync => Artifact moved: $savedId (type: ${artifact.artefactId}) to ${artifact.position}");
    
    // Move the artifact to the end of the list to bring it to the front
    if (base.showDirectional) {
      final artifacts = base.linearBoardController.artifacts;
      final index = artifacts.indexOf(artifact);
      if (index != -1 && index != artifacts.length - 1) {
        artifacts.removeAt(index);
        artifacts.add(artifact);
      }
    } else {
      final artifacts = base.talkingmatController.value;
      final index = artifacts.indexOf(artifact);
      if (index != -1 && index != artifacts.length - 1) {
        artifacts.removeAt(index);
        artifacts.add(artifact);
      }
    }
    
    _pushArtifactMoved(artifact);
  }

  // ---------------- Build snapshot ----------------

  Map<String, dynamic> _buildBoardSnapshot() {
    final List<Map<String, dynamic>> items = [];

    if (base.showDirectional) {
      // For linear board, include index information
      for (int i = 0; i < base.linearBoardController.artifacts.length; i++) {
        final item = base.linearBoardController.artifacts[i];
        if (item != null) {
          final size = item.sizeNotifier.value;
          items.add({
            'savedArtefactId': item.savedArtefactId,
            'id': item.artefactId,
            'name': item.baseArtefact?.name,
            'imageUrl': item.baseArtefact?.imageUrl,
            'soundUrl': item.baseArtefact?.soundUrl,
            'size': {'width': size.width, 'height': size.height},
            'index': i, // Include index for linear layout
          });
        }
      }
    } else {
      // For talking mat, include position information
      for (final a in base.talkingmatController.value) {
        final size = a.sizeNotifier.value;
        items.add({
          'savedArtefactId': a.savedArtefactId,
          'id': a.artefactId,
          'name': a.baseArtefact?.name,
          'imageUrl': a.baseArtefact?.imageUrl,
          'soundUrl': a.baseArtefact?.soundUrl,
          'size': {'width': size.width, 'height': size.height},
          if (a.position != null)
            'position': {'dx': a.position!.dx, 'dy': a.position!.dy},
        });
      }
    }

    return {
      'sessionId': sessionId,
      'layout': base.showDirectional ? 'linear' : 'talkingmat',
      'fieldCount': base.showDirectional ? base.linearBoardController.fieldCount : null,
      'items': items,
    };
  }

  // ---------------- Debounced update methods ----------------

  void _debouncedSizeUpdate(BoardArtefact artifact) {
    if (artifact.savedArtefactId == null) {
      debugPrint("RemoteSync => Cannot sync size update - artifact has no savedArtefactId");
      return;
    }
    
    // Cancel existing timer for this artifact instance
    _artifactUpdateTimers['size_${artifact.savedArtefactId}']?.cancel();
    
    // Create new debounced timer (100ms delay)
    _artifactUpdateTimers['size_${artifact.savedArtefactId}'] = Timer(const Duration(milliseconds: 100), () {
      debugPrint("RemoteSync => Artifact resized: ${artifact.savedArtefactId} (type: ${artifact.artefactId}) to ${artifact.sizeNotifier.value}");
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
        'savedArtefactId': artifact.savedArtefactId,
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
      debugPrint("RemoteSync => Pushed artifact added: ${artifact.savedArtefactId} (type: ${artifact.artefactId})");
    } catch (e) {
      debugPrint("RemoteSync => Failed to push artifact added: $e");
    }
  }

  Future<void> _pushArtifactRemoved(String savedArtefactId) async {
    if (!SignalRService().isConnected) return;

    final payload = {
      'sessionId': sessionId,
      'savedArtefactId': savedArtefactId,
    };

    try {
      await SignalRService().sendArtifactRemoved(payload);
      debugPrint("RemoteSync => Pushed artifact removed: $savedArtefactId");
    } catch (e) {
      debugPrint("RemoteSync => Failed to push artifact removed: $e");
    }
  }

  Future<void> _pushArtifactMoved(BoardArtefact artifact) async {
    if (!SignalRService().isConnected) {
      debugPrint("RemoteSync => Cannot push move - SignalR not connected");
      return;
    }
    if (artifact.position == null) {
      debugPrint("RemoteSync => Cannot push move - artifact has no position");
      return;
    }
    if (artifact.savedArtefactId == null) {
      debugPrint("RemoteSync => Cannot push move - artifact has no savedArtefactId");
      return;
    }

    final payload = {
      'sessionId': sessionId,
      'savedArtefactId': artifact.savedArtefactId,
      'position': {'dx': artifact.position!.dx, 'dy': artifact.position!.dy},
    };

    try {
      await SignalRService().sendArtifactMoved(payload);
      debugPrint("RemoteSync => Pushed artifact moved: ${artifact.savedArtefactId}");
    } catch (e) {
      debugPrint("RemoteSync => Failed to push artifact moved: $e");
    }
  }

  Future<void> _pushLinearArtifactMoved(BoardArtefact artifact, int fromIndex, int toIndex) async {
    if (!SignalRService().isConnected) {
      debugPrint("RemoteSync => Cannot push linear move - SignalR not connected");
      return;
    }
    if (artifact.savedArtefactId == null) {
      debugPrint("RemoteSync => Cannot push linear move - artifact has no savedArtefactId");
      return;
    }

    final payload = {
      'sessionId': sessionId,
      'savedArtefactId': artifact.savedArtefactId,
      'artifactId': artifact.artefactId,
      'fromIndex': fromIndex,
      'toIndex': toIndex,
    };

    try {
      await SignalRService().sendArtifactMoved(payload);
      debugPrint("RemoteSync => Pushed linear artifact moved: ${artifact.savedArtefactId} from $fromIndex to $toIndex");
    } catch (e) {
      debugPrint("RemoteSync => Failed to push linear artifact moved: $e");
    }
  }

  Future<void> _pushArtifactResized(BoardArtefact artifact) async {
    if (!SignalRService().isConnected) {
      debugPrint("RemoteSync => Cannot push resize - SignalR not connected");
      return;
    }
    if (artifact.savedArtefactId == null) {
      debugPrint("RemoteSync => Cannot push resize - artifact has no savedArtefactId");
      return;
    }

    final size = artifact.sizeNotifier.value;
    final payload = {
      'sessionId': sessionId,
      'savedArtefactId': artifact.savedArtefactId,
      'size': {'width': size.width, 'height': size.height},
    };

    try {
      await SignalRService().sendArtifactResized(payload);
      debugPrint("RemoteSync => Pushed artifact resized: ${artifact.savedArtefactId}");
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

  Future<void> _pushFieldCountChanged(int count) async {
    if (!SignalRService().isConnected) return;

    final payload = {
      'sessionId': sessionId,
      'count': count,
    };

    try {
      await SignalRService().sendFieldCountChanged(payload);
      debugPrint("RemoteSync => Pushed field count changed: $count");
    } catch (e) {
      debugPrint("RemoteSync => Failed to push field count changed: $e");
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
    final fieldCount = map['fieldCount'] as int?;

    debugPrint(
        "RemoteSync => Received update: layout=$layout, items=${items.length}, fieldCount=$fieldCount");

    // Force layout to match sender (don't toggle, just set it)
    final directional = (layout == 'linear');
    if (base.showDirectional != directional) {
      debugPrint(
          "RemoteSync => Switching layout from ${base.showDirectional ? 'linear' : 'talking mat'} to ${directional ? 'linear' : 'talking mat'}");
      base.switchCurrentBoard();
    }

    // Update field count for linear layout BEFORE adding artifacts
    if (directional && fieldCount != null && base.linearBoardController.fieldCount != fieldCount) {
      debugPrint("RemoteSync => Updating field count to $fieldCount");
      base.linearBoardController.setFieldCount(fieldCount);
    }

    // Get current artifacts
    final currentArtifacts = base.showDirectional
        ? base.linearBoardController.artifacts.whereType<BoardArtefact>().toList()
        : base.talkingmatController.value;

    // Create a map of current artifacts by savedArtefactId
    final artifactMap = <String?, BoardArtefact>{};
    for (final artifact in currentArtifacts) {
      if (artifact.savedArtefactId != null) {
        artifactMap[artifact.savedArtefactId] = artifact;
      }
    }

    // Track which artifact savedArtefactIds we've seen in the update
    final updatedSavedIds = <String>{};

    // Update or add artifacts
    for (final item in items) {
      if (item is! Map) continue;

      final savedArtefactId = item['savedArtefactId'] as String?;
      final id = item['id'] as String?;
      if (id == null) continue;

      if (savedArtefactId != null) {
        updatedSavedIds.add(savedArtefactId);
      }

      final existing = savedArtefactId != null ? artifactMap[savedArtefactId] : null;
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
          imageUrl: _fixLocalhostUrl(item['imageUrl']),
          soundUrl: _fixLocalhostUrl(item['soundUrl']),
        );

        // Build headers for network image authentication
        final token = GetIt.instance.get<Token>().value;
        Map<String, String>? headers;
        if (token != null) headers = {'Authorization': 'Bearer $token'};

        final boardItem = BoardArtefact.fromArtefact(artefact, headers: headers);
        boardItem.savedArtefactId = savedArtefactId;

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

        // Handle index for linear board
        final index = item['index'] as int?;
        if (base.showDirectional && index != null) {
          // Add artifact at specific index for linear board
          base.linearBoardController.addArtifact(boardItem, index: index);
        } else {
          // Add artifact normally for talking mat
          base.addArtifactToCurrentBoard(boardItem);
        }
      }
    }

    // Remove artifacts that weren't in the update
    if (base.showDirectional) {
      for (int i = base.linearBoardController.artifacts.length - 1; i >= 0; i--) {
        final artifact = base.linearBoardController.artifacts[i];
        if (artifact != null && artifact.savedArtefactId != null && !updatedSavedIds.contains(artifact.savedArtefactId)) {
          base.linearBoardController.removeArtifact(i);
        }
      }
    } else {
      base.talkingmatController.value.removeWhere(
        (artifact) => artifact.savedArtefactId != null && !updatedSavedIds.contains(artifact.savedArtefactId!)
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

    final savedArtefactId = artifactData['savedArtefactId'] as String?;
    final id = artifactData['id'] as String?;
    if (id == null) return;

    debugPrint("RemoteSync => Received artifact added: $savedArtefactId (type: $id)");

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
    // Use provided savedArtefactId or generate one if missing
    boardItem.savedArtefactId = savedArtefactId ?? _generateSavedArtefactId();
    debugPrint("RemoteSync => Created artifact with savedArtefactId: ${boardItem.savedArtefactId}");

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

    final savedArtefactId = map['savedArtefactId'] as String?;
    final artefactId = map['artifactId'] as String?;
    if (savedArtefactId == null) return;

    debugPrint("RemoteSync => Received artifact removed: $savedArtefactId (type: $artefactId)");

    // Find and remove the artifact
    if (base.showDirectional) {
      final artifacts = base.linearBoardController.artifacts;
      for (int i = artifacts.length - 1; i >= 0; i--) {
        final artifact = artifacts[i];
        if (artifact?.savedArtefactId == savedArtefactId) {
          base.linearBoardController.removeArtifact(i);
          debugPrint("RemoteSync => Removed artifact from linear board at index $i");
          notifyView();
          return;
        }
      }
    } else {
      final artifacts = base.talkingmatController.value;
      final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
        (a) => a?.savedArtefactId == savedArtefactId,
        orElse: () => null,
      );
      if (artifact != null) {
        base.talkingmatController.removeArtifact(artifact);
        debugPrint("RemoteSync => Removed artifact from talking mat");
        notifyView();
        return;
      }
    }
    debugPrint("RemoteSync => Artifact $savedArtefactId not found for removal");
  }

  void _handleArtifactMoved(dynamic data) {
    if (data is! Map) return;
    if (isOwner) return;

    final map = data.cast<String, dynamic>();
    final incomingSessionId = map['sessionId'] as String?;
    if (incomingSessionId != sessionId) return;

    final savedArtefactId = map['savedArtefactId'] as String?;
    if (savedArtefactId == null) return;

    // Check if this is a linear board index-based move
    final fromIndex = map['fromIndex'] as int?;
    final toIndex = map['toIndex'] as int?;
    
    if (base.showDirectional && fromIndex != null && toIndex != null) {
      // Linear board index-based move
      debugPrint("RemoteSync => Received linear artifact moved: $savedArtefactId from $fromIndex to $toIndex");
      
      // Find the artifact by savedArtefactId
      int? actualFromIndex;
      for (int i = 0; i < base.linearBoardController.artifacts.length; i++) {
        if (base.linearBoardController.artifacts[i]?.savedArtefactId == savedArtefactId) {
          actualFromIndex = i;
          break;
        }
      }
      
      if (actualFromIndex != null) {
        base.linearBoardController.moveArtifact(actualFromIndex, toIndex);
        debugPrint("RemoteSync => Moved artifact from slot $actualFromIndex to $toIndex");
        notifyView();
      } else {
        debugPrint("RemoteSync => Artifact $savedArtefactId not found in linear board");
      }
      return;
    }
    
    // Original position-based move for TalkingMat
    final position = map['position'];
    if (position == null) return;

    debugPrint("RemoteSync => Received artifact moved: $savedArtefactId to (${position['dx']}, ${position['dy']})");

    // TalkingMat - need to trigger ValueNotifier by reassigning
    final artifacts = base.talkingmatController.value;
    final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
      (a) => a?.savedArtefactId == savedArtefactId,
      orElse: () => null,
    );
    
    if (artifact != null) {
      artifact.position = Offset(
        (position['dx'] as num).toDouble(),
        (position['dy'] as num).toDouble(),
      );
      
      // Move artifact to end of list to bring it to front
      final updatedArtifacts = List<BoardArtefact>.from(artifacts);
      updatedArtifacts.remove(artifact);
      updatedArtifacts.add(artifact);
      
      // Trigger ValueNotifier by reassigning the list
      base.talkingmatController.value = updatedArtifacts;
      debugPrint("RemoteSync => Updated artifact position on talking mat (moved to front)");
      notifyView();
    } else {
      debugPrint("RemoteSync => Artifact $savedArtefactId not found for move");
    }
  }

  void _handleArtifactResized(dynamic data) {
    if (data is! Map) return;
    if (isOwner) return;

    final map = data.cast<String, dynamic>();
    final incomingSessionId = map['sessionId'] as String?;
    if (incomingSessionId != sessionId) return;

    final savedArtefactId = map['savedArtefactId'] as String?;
    final artefactId = map['artifactId'] as String?;
    final size = map['size'];
    if (savedArtefactId == null || size == null) return;

    debugPrint("RemoteSync => Received artifact resized: $savedArtefactId (type: $artefactId) to ${size['width']}x${size['height']}");

    // Find the artifact and update its size
    if (base.showDirectional) {
      // Linear board
      final artifacts = base.linearBoardController.artifacts.whereType<BoardArtefact>().toList();
      final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
        (a) => a?.savedArtefactId == savedArtefactId,
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
        debugPrint("RemoteSync => Artifact $savedArtefactId not found for resize");
      }
    } else {
      // TalkingMat
      final artifacts = base.talkingmatController.value;
      final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
        (a) => a?.savedArtefactId == savedArtefactId,
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
        debugPrint("RemoteSync => Artifact $savedArtefactId not found for resize");
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

  void _handleFieldCountChanged(dynamic data) {
    if (data is! Map) return;
    if (isOwner) return;

    final map = data.cast<String, dynamic>();
    final incomingSessionId = map['sessionId'] as String?;
    if (incomingSessionId != sessionId) return;

    final count = map['count'] as int?;
    if (count == null) return;

    debugPrint("RemoteSync => Received field count changed: $count (current: ${base.linearBoardController.fieldCount})");

    if (base.linearBoardController.fieldCount != count) {
      debugPrint("RemoteSync => Updating field count from ${base.linearBoardController.fieldCount} to $count");
      base.linearBoardController.setFieldCount(count);
      notifyView();
    } else {
      debugPrint("RemoteSync => Field count already correct");
    }
  }

  // ---------------- Remote session management ----------------

  void _clearBoard() {
    debugPrint("RemoteSync => Clearing all artifacts from board");
    if (base.showDirectional) {
      // Clear linear board
      while (base.linearBoardController.artifacts.isNotEmpty) {
        base.linearBoardController.removeArtifact(0);
      }
    } else {
      // Clear talking mat by setting empty list
      base.talkingmatController.value = [];
    }
    notifyView();
  }

  void _setupRemoteSession() {
    // Wait for TalkingMat widget to be built
    Future.delayed(const Duration(milliseconds: 100), () {
      if (base.talkingMatKey.currentState != null) {
        // Disable auto-save for non-owner
        if (!isOwner) {
          base.talkingMatKey.currentState!.setRemoteSession(true);
          debugPrint("RemoteSync => Disabled auto-save for non-owner");
        } else {
          debugPrint("RemoteSync => Auto-save remains enabled for owner (TalkingMat state accessible: ${base.talkingMatKey.currentState != null})");
        }
      } else {
        debugPrint("RemoteSync => WARNING: TalkingMat state not accessible yet");
      }
    });
  }

  void _cleanupRemoteSession() {
    if (base.talkingMatKey.currentState != null) {
      if (!isOwner) {
        base.talkingMatKey.currentState!.setRemoteSession(false);
        debugPrint("RemoteSync => Re-enabled auto-save for non-owner after remote session");
      }
    }
  }

  // Rebuild base.talkingMat to include remote sync callbacks for owner
  void _setupOwnerCallbacks() {
    if (!isOwner) return;
    
    debugPrint("RemoteSync => Setting up owner callbacks");
    
    // Rebuild the TalkingMat widget with callbacks
    base.talkingMat = TalkingMat(
      key: base.talkingMatKey,
      controller: base.talkingmatController,
      onArtifactPositionChanged: (artifact) {
        onArtifactPositionChanged(artifact);
      },
      onArtifactRemoved: (artifact) {
        removeArtifact(artifact);
      },
      onBoardLoaded: () {
        debugPrint("RemoteSync => Board load complete, setting up remote sync");
        _onOwnerBoardLoaded();
      },
    );
    
    // Rebuild the LinearBoard widget with callbacks
    base.linearBoard = LinearBoard(
      key: base.linearBoardKey,
      linearBoardController: base.linearBoardController,
      onArtifactRemoved: (artifact) {
        removeArtifact(artifact);
      },
      onArtifactMoved: (artifact, fromIndex, toIndex) {
        debugPrint(
            "RemoteSync => Artifact moved in linear board: ${artifact.savedArtefactId} from $fromIndex to $toIndex");
        _pushLinearArtifactMoved(artifact, fromIndex, toIndex);
      },
    );
  }

  void _onOwnerBoardLoaded() {
    debugPrint("RemoteSync => Owner board loaded, initializing remote sync");
    
    // Attach size listeners to all existing artifacts
    _attachSizeListenersToExistingArtifacts();
    
    // Send current board state to remote participant
    _pushFullBoard();
  }
  
  // Attach size listeners to existing artifacts on owner's board
  void _attachSizeListenersToExistingArtifacts() {
    if (!isOwner) return;
    
    final artifacts = base.showDirectional 
        ? base.linearBoardController.artifacts 
        : base.talkingmatController.value;
    
    debugPrint("RemoteSync => Attaching size listeners to ${artifacts.length} existing artifacts");
    
    for (final artifact in artifacts) {
      if (artifact == null) continue;
      
      // Generate savedArtefactId if missing
      if (artifact.savedArtefactId == null) {
        artifact.savedArtefactId = _generateSavedArtefactId();
        debugPrint("RemoteSync => Generated savedArtefactId for existing artifact: ${artifact.savedArtefactId}");
      }
      
      // Attach size listener if not already attached
      if (!_sizeListeners.containsKey(artifact.savedArtefactId)) {
        void listener() {
          debugPrint("RemoteSync => Size listener triggered for ${artifact.savedArtefactId}");
          _debouncedSizeUpdate(artifact);
        }
        _sizeListeners[artifact.savedArtefactId!] = listener;
        artifact.sizeNotifier.addListener(listener);
        debugPrint("RemoteSync => Attached size listener to existing artifact ${artifact.savedArtefactId}");
      }
    }
  }
  
  // Listen to controller changes to detect artifact additions and trigger auto-save
  void _onControllerChanged() {
    if (!isOwner || base.showDirectional) return;
    
    final currentCount = base.talkingmatController.value.length;
    if (currentCount > _lastArtifactCount) {
      // Artifact was added, trigger auto-save
      debugPrint("RemoteSync => Detected artifact addition ($_lastArtifactCount -> $currentCount), triggering auto-save");
      
      // Trigger auto-save through TalkingMat state's public method
      if (base.talkingMatKey.currentState != null) {
        base.talkingMatKey.currentState!.triggerAutoSave();
        debugPrint("RemoteSync => Auto-save triggered for newly added artifact");
      } else {
        debugPrint("RemoteSync => WARNING: TalkingMat state not available for auto-save");
      }
    }
    _lastArtifactCount = currentCount;
  }

  void _onLinearBoardChanged() {
    if (!isOwner || !base.showDirectional) return;
    
    final currentFieldCount = base.linearBoardController.fieldCount;
    if (currentFieldCount != _lastFieldCount) {
      // Field count changed, push update to remote participants
      debugPrint("RemoteSync => Detected field count change ($_lastFieldCount -> $currentFieldCount), pushing update");
      _pushFieldCountChanged(currentFieldCount);
      _lastFieldCount = currentFieldCount;
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
