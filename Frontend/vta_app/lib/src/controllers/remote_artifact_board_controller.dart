import 'dart:async';
import 'dart:math';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/services/remote_board_sync_receiver.dart';
import 'package:vta_app/src/services/remote_board_sync_sender.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/ui/widgets/board/linear_board.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import 'package:logging/logging.dart';


final _log = Logger('RemoteArtifactBoardController');
typedef VoidCallback = void Function();

// Generate a UUID v4 for savedArtefactId
String _generateSavedArtefactId() {
  final random = Random();
  final values = List<int>.generate(16, (i) => random.nextInt(256));

  values[6] = (values[6] & 0x0f) | 0x40;
  values[8] = (values[8] & 0x3f) | 0x80;

  final hex =
      values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Thin orchestrator for remote board sessions.
///
/// Delegates outbound sync to [RemoteBoardSyncSender] and inbound sync
/// to [RemoteBoardSyncReceiver].  Owns only UI-level actions (add / remove /
/// switch / move) and lifecycle (setup / dispose).
///
/// Reduced from 1,209 → ~300 LOC as part of Phase 3.2.
class RemoteArtifactBoardController {
  final ArtifactBoardController base;
  final String sessionId;
  final bool isOwner;
  final VoidCallback notifyView;
  final SettingsController settingsController;

  late final RemoteBoardSyncSender _sender;
  late final RemoteBoardSyncReceiver _receiver;

  // Track artifact count to detect additions (owner only)
  int _lastArtifactCount = 0;

  // Track field count to detect changes (owner only)
  int _lastFieldCount = 0;

  RemoteArtifactBoardController({
    required this.sessionId,
    required this.notifyView,
    required this.settingsController,
    required this.isOwner,
    ArtifactBoardController? existingController,
  }) : base = existingController ??
            ArtifactBoardController(
                notifyView: notifyView, settingsController: settingsController) {
    _sender = RemoteBoardSyncSender(base: base, sessionId: sessionId);
    _receiver = RemoteBoardSyncReceiver(
      base: base,
      sessionId: sessionId,
      isOwner: isOwner,
      notifyView: notifyView,
    );

    // Register inbound SignalR callbacks
    _receiver.registerCallbacks();

    _log.fine(
        "RemoteSync => Initializing (isOwner=$isOwner, sessionId=$sessionId)");
    _log.fine(
        "RemoteSync => SignalR connected: ${SignalRService().isConnected}");

    _setupRemoteSession();

    if (isOwner) {
      _setupOwnerCallbacks();

      base.talkingmatController.addListener(_onControllerChanged);
      _lastArtifactCount = base.talkingmatController.value.length;

      base.linearBoardController.addListener(_onLinearBoardChanged);
      _lastFieldCount = base.linearBoardController.fieldCount;
    } else {
      _log.fine(
          "RemoteSync => Non-owner clearing artifacts and waiting for board state from owner");
      _clearBoard();
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────

  void dispose() {
    if (isOwner) {
      base.talkingmatController.removeListener(_onControllerChanged);
      base.linearBoardController.removeListener(_onLinearBoardChanged);
    }

    _sender.dispose();
    _receiver.unregisterCallbacks();
    _cleanupRemoteSession();

    if (!isOwner) {
      base.dispose();
    }
  }

  // ── Getters ───────────────────────────────────────────────────

  bool get showDirectional => base.showDirectional;

  TalkingMat? get ownerTalkingMat {
    if (!isOwner || base.showDirectional) return null;
    return base.talkingMat;
  }

  TalkingMat? get talkingMat {
    if (isOwner) return base.talkingMat;
    return TalkingMat(
      controller: base.talkingmatController,
      readOnly: true,
    );
  }

  LinearBoard? get linearBoard => base.linearBoard;

  // ── UI actions (owner syncs changes) ──────────────────────────

  void addArtifact(BoardArtefact artefact) {
    if (!isOwner) return;

    artefact.savedArtefactId ??= _generateSavedArtefactId();

    _sender.attachSizeListener(artefact);
    base.addArtifactToCurrentBoard(artefact);
    notifyView();
    _sender.pushArtifactAdded(artefact);
  }

  void removeArtifact(BoardArtefact artefact) {
    if (!isOwner) return;

    _sender.removeSizeListener(artefact);

    if (base.showDirectional) {
      final index = base.linearBoardController.artifacts.indexOf(artefact);
      if (index != -1) {
        base.linearBoardController.removeArtifact(index);
      }
    } else {
      base.talkingmatController.removeArtifact(artefact);
    }

    notifyView();

    if (artefact.savedArtefactId != null) {
      _sender.pushArtifactRemoved(artefact.savedArtefactId!);
    }
  }

  void switchBoard() {
    if (!isOwner) return;

    base.switchCurrentBoard();
    notifyView();
    _sender.debouncedLayoutChange();
  }

  void onArtifactPositionChanged(BoardArtefact artifact) {
    if (!isOwner) return;

    if (artifact.savedArtefactId == null) return;

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

    _sender.pushArtifactMoved(artifact);
  }

  // ── Owner setup ───────────────────────────────────────────────

  void _setupOwnerCallbacks() {
    if (!isOwner) return;

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
        _log.fine("RemoteSync => Board load complete, setting up remote sync");
        _onOwnerBoardLoaded();
      },
    );

    base.linearBoard = LinearBoard(
      key: base.linearBoardKey,
      linearBoardController: base.linearBoardController,
      onArtifactRemoved: (artifact) {
        removeArtifact(artifact);
      },
      onArtifactMoved: (artifact, fromIndex, toIndex) {
        _sender.pushLinearArtifactMoved(artifact, fromIndex, toIndex);
      },
    );
  }

  void _onOwnerBoardLoaded() {
    _log.fine("RemoteSync => Owner board loaded, initializing remote sync");
    _sender.attachSizeListenersToExistingArtifacts();
    _sender.pushFullBoard();
  }

  // ── Change listeners ──────────────────────────────────────────

  void _onControllerChanged() {
    if (!isOwner || base.showDirectional) return;

    final currentCount = base.talkingmatController.value.length;
    if (currentCount > _lastArtifactCount) {
      if (base.talkingMatKey.currentState != null) {
        base.talkingMatKey.currentState!.triggerAutoSave();
      }
    }
    _lastArtifactCount = currentCount;
  }

  void _onLinearBoardChanged() {
    if (!isOwner || !base.showDirectional) return;

    final currentFieldCount = base.linearBoardController.fieldCount;
    if (currentFieldCount != _lastFieldCount) {
      _sender.pushFieldCountChanged(currentFieldCount);
      _lastFieldCount = currentFieldCount;
    }
  }

  // ── Session management ────────────────────────────────────────

  void _clearBoard() {
    if (base.showDirectional) {
      while (base.linearBoardController.artifacts.isNotEmpty) {
        base.linearBoardController.removeArtifact(0);
      }
    } else {
      base.talkingmatController.value = [];
    }
    notifyView();
  }

  void _setupRemoteSession() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (base.talkingMatKey.currentState != null) {
        if (!isOwner) {
          base.talkingMatKey.currentState!.setRemoteSession(true);
        }
      }
    });
  }

  void _cleanupRemoteSession() {
    if (base.talkingMatKey.currentState != null) {
      if (!isOwner) {
        base.talkingMatKey.currentState!.setRemoteSession(false);
      }
    }
  }
}
