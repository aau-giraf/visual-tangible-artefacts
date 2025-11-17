import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/ui/widgets/board/linear_board.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';

typedef VoidCallback = void Function();

class RemoteArtifactBoardController {
  final ArtifactBoardController base;
  final String sessionId;
  final bool isOwner;
  final VoidCallback notifyView;
  late bool _initialized;

  RemoteArtifactBoardController({
    required this.sessionId,
    required this.notifyView,
    required this.isOwner,
    ArtifactBoardController? existingController,
  })  : base = existingController ??
            ArtifactBoardController(notifyView: notifyView),
        _initialized = false {
    SignalRService().onBoardUpdated = _handleRemoteUpdate;

    debugPrint(
        "RemoteSync => Initializing (isOwner=$isOwner, sessionId=$sessionId)");
    debugPrint(
        "RemoteSync => SignalR connected: ${SignalRService().isConnected}");

    // Hook into talkingmat position changes for sync
    if (isOwner && base.talkingMat != null) {
      // Get the state to add the callback
      // This will be set up in initState when widgets are built
    }

    if (isOwner) {
      // Owner: load their existing board and send it
      debugPrint("RemoteSync => Owner: sending current board snapshot...");
      Future.delayed(const Duration(milliseconds: 100), () {
        _pushFullBoard();
        _initialized = true;
      });
    } else {
      // Non-owner: clear their board and wait for owner's snapshot
      _clearBoard();
      _initialized = true;
      debugPrint(
          "RemoteSync => Non-owner: board cleared, waiting for update...");
    }
  }

  void dispose() {
    if (SignalRService().onBoardUpdated == _handleRemoteUpdate) {
      SignalRService().onBoardUpdated = null;
    }
    base.dispose();
  }

  bool get showDirectional => base.showDirectional;
  TalkingMat? get talkingMat => base.talkingMat;
  LinearBoard? get linearBoard => base.linearBoard;

  // ---------------- UI actions (owner syncs changes) ----------------

  void addArtifact(BoardArtefact artefact) {
    if (!isOwner) {
      debugPrint("RemoteSync => Non-owner cannot add artifacts");
      return;
    }

    base.addArtifactToCurrentBoard(artefact);
    notifyView();
    _pushFullBoard();
  }

  void switchBoard() {
    if (!isOwner) {
      debugPrint("RemoteSync => Non-owner cannot switch board");
      return;
    }

    base.switchCurrentBoard();
    notifyView();
    _pushFullBoard();
  }

  /// Called when an artifact position changes (from drag)
  void onArtifactPositionChanged(BoardArtefact artifact) {
    if (!isOwner) {
      debugPrint("RemoteSync => Non-owner cannot move artifacts");
      return;
    }

    debugPrint(
        "RemoteSync => Artifact moved: ${artifact.artefactId} to ${artifact.position}");
    _pushFullBoard();
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

    // clear old board
    _clearBoard();

    // rebuild items
    for (final item in items) {
      if (item is! Map) continue;

      final artefact = Artefact(
        artefactId: item['id'],
        name: item['name'],
        imageUrl: item['imageUrl'],
        soundUrl: item['soundUrl'],
      );

      final boardItem = BoardArtefact.fromArtefact(artefact);

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

    notifyView();
    debugPrint("RemoteSync => Board updated with ${items.length} items");
  }

  void _clearBoard() {
    if (base.showDirectional) {
      for (int i = 0; i < base.linearBoardController.artifacts.length; i++) {
        base.linearBoardController.artifacts[i] = null;
      }
    } else {
      base.talkingmatController.value.clear();
    }
  }
}
