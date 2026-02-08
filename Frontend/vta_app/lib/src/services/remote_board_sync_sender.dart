import 'dart:async';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:logging/logging.dart';


final _log = Logger('RemoteBoardSyncSender');
typedef VoidCallback = void Function();

/// Handles all outbound sync — serialising board state and pushing deltas
/// to the remote participant via SignalR.
///
/// Owns: debounce timers, size listeners, snapshot building, all `_push*`
/// methods.  Extracted from `RemoteArtifactBoardController` (Phase 3.2).
class RemoteBoardSyncSender {
  final ArtifactBoardController base;
  final String sessionId;

  // Debounce timers
  Timer? _layoutChangeTimer;
  final Map<String, Timer?> _artifactUpdateTimers = {};

  // Size listeners (savedArtefactId → listener)
  final Map<String, VoidCallback> _sizeListeners = {};

  RemoteBoardSyncSender({required this.base, required this.sessionId});

  // ── Lifecycle ──────────────────────────────────────────────────

  void dispose() {
    _layoutChangeTimer?.cancel();
    for (var timer in _artifactUpdateTimers.values) {
      timer?.cancel();
    }
    _artifactUpdateTimers.clear();
    _sizeListeners.clear();
  }

  // ── Size listener management ──────────────────────────────────

  /// Attach a debounced size listener if not already tracked.
  void attachSizeListener(BoardArtefact artifact) {
    final id = artifact.savedArtefactId;
    if (id == null || _sizeListeners.containsKey(id)) return;

    void listener() {
      _log.fine("RemoteSync => Size listener triggered for $id");
      _debouncedSizeUpdate(artifact);
    }

    _sizeListeners[id] = listener;
    artifact.sizeNotifier.addListener(listener);
  }

  /// Remove and unlisten a specific artifact's size listener.
  void removeSizeListener(BoardArtefact artifact) {
    final id = artifact.savedArtefactId;
    if (id == null) return;
    final listener = _sizeListeners.remove(id);
    if (listener != null) {
      artifact.sizeNotifier.removeListener(listener);
    }
  }

  /// Attach size listeners to all existing artifacts on the board.
  void attachSizeListenersToExistingArtifacts() {
    final artifacts = base.showDirectional
        ? base.linearBoardController.artifacts
        : base.talkingmatController.value;

    _log.fine(
        "RemoteSync => Attaching size listeners to ${artifacts.length} existing artifacts");

    for (final artifact in artifacts) {
      if (artifact == null) continue;
      attachSizeListener(artifact);
    }
  }

  // ── Debouncing ────────────────────────────────────────────────

  void _debouncedSizeUpdate(BoardArtefact artifact) {
    if (artifact.savedArtefactId == null) return;

    _artifactUpdateTimers['size_${artifact.savedArtefactId}']?.cancel();
    _artifactUpdateTimers['size_${artifact.savedArtefactId}'] =
        Timer(const Duration(milliseconds: 100), () {
      _log.fine(
          "RemoteSync => Artifact resized: ${artifact.savedArtefactId} to ${artifact.sizeNotifier.value}");
      pushArtifactResized(artifact);
    });
  }

  /// Debounce layout change, then push layout + full board.
  void debouncedLayoutChange() {
    _layoutChangeTimer?.cancel();
    _layoutChangeTimer = Timer(const Duration(milliseconds: 300), () {
      pushLayoutChanged();
      Future.delayed(const Duration(milliseconds: 100), () {
        pushFullBoard();
      });
    });
  }

  // ── Snapshot ──────────────────────────────────────────────────

  Map<String, dynamic> buildBoardSnapshot() {
    final List<Map<String, dynamic>> items = [];

    if (base.showDirectional) {
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
            'index': i,
          });
        }
      }
    } else {
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
      'fieldCount':
          base.showDirectional ? base.linearBoardController.fieldCount : null,
      'items': items,
    };
  }

  // ── Push methods ──────────────────────────────────────────────

  Future<void> pushArtifactAdded(BoardArtefact artifact) async {
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
          'position': {
            'dx': artifact.position!.dx,
            'dy': artifact.position!.dy
          },
      },
    };

    try {
      await SignalRService().sendArtifactAdded(payload);
      _log.fine(
          "RemoteSync => Pushed artifact added: ${artifact.savedArtefactId}");
    } catch (e) {
      _log.fine("RemoteSync => Failed to push artifact added: $e");
    }
  }

  Future<void> pushArtifactRemoved(String savedArtefactId) async {
    if (!SignalRService().isConnected) return;

    final payload = {
      'sessionId': sessionId,
      'savedArtefactId': savedArtefactId,
    };

    try {
      await SignalRService().sendArtifactRemoved(payload);
      _log.fine("RemoteSync => Pushed artifact removed: $savedArtefactId");
    } catch (e) {
      _log.fine("RemoteSync => Failed to push artifact removed: $e");
    }
  }

  Future<void> pushArtifactMoved(BoardArtefact artifact) async {
    if (!SignalRService().isConnected) return;
    if (artifact.position == null || artifact.savedArtefactId == null) return;

    final payload = {
      'sessionId': sessionId,
      'savedArtefactId': artifact.savedArtefactId,
      'position': {'dx': artifact.position!.dx, 'dy': artifact.position!.dy},
    };

    try {
      await SignalRService().sendArtifactMoved(payload);
      _log.fine(
          "RemoteSync => Pushed artifact moved: ${artifact.savedArtefactId}");
    } catch (e) {
      _log.fine("RemoteSync => Failed to push artifact moved: $e");
    }
  }

  Future<void> pushLinearArtifactMoved(
      BoardArtefact artifact, int fromIndex, int toIndex) async {
    if (!SignalRService().isConnected) return;
    if (artifact.savedArtefactId == null) return;

    final payload = {
      'sessionId': sessionId,
      'savedArtefactId': artifact.savedArtefactId,
      'artifactId': artifact.artefactId,
      'fromIndex': fromIndex,
      'toIndex': toIndex,
    };

    try {
      await SignalRService().sendArtifactMoved(payload);
      _log.fine(
          "RemoteSync => Pushed linear artifact moved: ${artifact.savedArtefactId} from $fromIndex to $toIndex");
    } catch (e) {
      _log.fine("RemoteSync => Failed to push linear artifact moved: $e");
    }
  }

  Future<void> pushArtifactResized(BoardArtefact artifact) async {
    if (!SignalRService().isConnected) return;
    if (artifact.savedArtefactId == null) return;

    final size = artifact.sizeNotifier.value;
    final payload = {
      'sessionId': sessionId,
      'savedArtefactId': artifact.savedArtefactId,
      'size': {'width': size.width, 'height': size.height},
    };

    try {
      await SignalRService().sendArtifactResized(payload);
      _log.fine(
          "RemoteSync => Pushed artifact resized: ${artifact.savedArtefactId}");
    } catch (e) {
      _log.fine("RemoteSync => Failed to push artifact resized: $e");
    }
  }

  Future<void> pushLayoutChanged() async {
    if (!SignalRService().isConnected) return;

    final payload = {
      'sessionId': sessionId,
      'layout': base.showDirectional ? 'linear' : 'talkingmat',
    };

    try {
      await SignalRService().sendLayoutChanged(payload);
      _log.fine("RemoteSync => Pushed layout changed: ${payload['layout']}");
    } catch (e) {
      _log.fine("RemoteSync => Failed to push layout changed: $e");
    }
  }

  Future<void> pushFieldCountChanged(int count) async {
    if (!SignalRService().isConnected) return;

    final payload = {
      'sessionId': sessionId,
      'count': count,
    };

    try {
      await SignalRService().sendFieldCountChanged(payload);
      _log.fine("RemoteSync => Pushed field count changed: $count");
    } catch (e) {
      _log.fine("RemoteSync => Failed to push field count changed: $e");
    }
  }

  Future<void> pushFullBoard() async {
    _log.fine("RemoteSync => _pushFullBoard called");
    if (!SignalRService().isConnected) {
      _log.fine("RemoteSync => ERROR: Not connected, skipping push");
      return;
    }

    final payload = buildBoardSnapshot();
    _log.fine(
        "RemoteSync => Built snapshot: ${payload['items'].length} items");

    try {
      await SignalRService().updateBoard(payload);
      _log.fine(
          "RemoteSync => SUCCESS: Pushed board (${payload['items'].length} items, layout=${payload['layout']})");
    } catch (e) {
      _log.fine("RemoteSync => EXCEPTION: Push failed: $e");
      rethrow;
    }
  }
}
