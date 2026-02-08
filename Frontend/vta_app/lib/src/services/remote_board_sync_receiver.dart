import 'dart:math';
import 'dart:ui';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/utilities/platform_utils.dart';
import 'package:logging/logging.dart';


final _log = Logger('RemoteBoardSyncReceiver');
typedef VoidCallback = void Function();

/// Fix localhost URLs to use the correct API URL for the current platform
String? _fixLocalhostUrl(String? url) {
  if (url == null || url.isEmpty) return url;

  if (url.contains('localhost:5192')) {
    final apiUrl = PlatformUtils.getApiUrl();
    final baseUrl = apiUrl.endsWith('/api/')
        ? apiUrl.substring(0, apiUrl.length - 5)
        : apiUrl;
    return url.replaceAll('http://localhost:5192', baseUrl);
  }

  return url;
}

/// Generate a UUID v4 for savedArtefactId
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

/// Handles all inbound sync — receives SignalR delta/full-board events
/// and applies them to the local [ArtifactBoardController].
///
/// Owns: SignalR callback registration/unregistration, all `_handle*`
/// methods.  Extracted from `RemoteArtifactBoardController` (Phase 3.2).
class RemoteBoardSyncReceiver {
  final ArtifactBoardController base;
  final String sessionId;
  final bool isOwner;
  final VoidCallback notifyView;

  RemoteBoardSyncReceiver({
    required this.base,
    required this.sessionId,
    required this.isOwner,
    required this.notifyView,
  });

  // ── Lifecycle ──────────────────────────────────────────────────

  /// Register all SignalR inbound callbacks.
  void registerCallbacks() {
    SignalRService().onBoardUpdated = _handleRemoteUpdate;
    SignalRService().onArtifactAdded = _handleArtifactAdded;
    SignalRService().onArtifactRemoved = _handleArtifactRemoved;
    SignalRService().onArtifactMoved = _handleArtifactMoved;
    SignalRService().onArtifactResized = _handleArtifactResized;
    SignalRService().onLayoutChanged = _handleLayoutChanged;
    SignalRService().onFieldCountChanged = _handleFieldCountChanged;
  }

  /// Unregister SignalR callbacks (only if still ours).
  void unregisterCallbacks() {
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
    if (SignalRService().onFieldCountChanged == _handleFieldCountChanged) {
      SignalRService().onFieldCountChanged = null;
    }
  }

  // ── Full board update ─────────────────────────────────────────

  void _handleRemoteUpdate(dynamic data) {
    if (data is! Map) {
      _log.fine("RemoteSync => Invalid data type: ${data.runtimeType}");
      return;
    }
    if (isOwner) return;

    final map = data.cast<String, dynamic>();
    final incomingSessionId = map['sessionId'] as String?;
    if (incomingSessionId != sessionId) return;

    final layout = map['layout'] as String?;
    final items = (map['items'] as List?) ?? [];
    final fieldCount = map['fieldCount'] as int?;

    _log.fine(
        "RemoteSync => Received update: layout=$layout, items=${items.length}, fieldCount=$fieldCount");

    // Force layout to match sender
    final directional = (layout == 'linear');
    if (base.showDirectional != directional) {
      base.switchCurrentBoard();
    }

    // Update field count for linear layout BEFORE adding artifacts
    if (directional &&
        fieldCount != null &&
        base.linearBoardController.fieldCount != fieldCount) {
      base.linearBoardController.setFieldCount(fieldCount);
    }

    // Get current artifacts
    final currentArtifacts = base.showDirectional
        ? base.linearBoardController.artifacts
            .whereType<BoardArtefact>()
            .toList()
        : base.talkingmatController.value;

    // Create a map of current artifacts by savedArtefactId
    final artifactMap = <String?, BoardArtefact>{};
    for (final artifact in currentArtifacts) {
      if (artifact.savedArtefactId != null) {
        artifactMap[artifact.savedArtefactId] = artifact;
      }
    }

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

      final existing =
          savedArtefactId != null ? artifactMap[savedArtefactId] : null;
      if (existing != null) {
        _updateArtifactFromData(existing, item);
      } else {
        final boardItem = _createBoardArtifactFromData(item, id, savedArtefactId);
        final index = item['index'] as int?;
        if (base.showDirectional && index != null) {
          base.linearBoardController.addArtifact(boardItem, index: index);
        } else {
          base.addArtifactToCurrentBoard(boardItem);
        }
      }
    }

    // Remove artifacts that weren't in the update
    if (base.showDirectional) {
      for (int i = base.linearBoardController.artifacts.length - 1;
          i >= 0;
          i--) {
        final artifact = base.linearBoardController.artifacts[i];
        if (artifact != null &&
            artifact.savedArtefactId != null &&
            !updatedSavedIds.contains(artifact.savedArtefactId)) {
          base.linearBoardController.removeArtifact(i);
        }
      }
    } else {
      base.talkingmatController.value.removeWhere((artifact) =>
          artifact.savedArtefactId != null &&
          !updatedSavedIds.contains(artifact.savedArtefactId!));
    }

    notifyView();
    _log.fine("RemoteSync => Board updated with ${items.length} items");
  }

  // ── Delta handlers ────────────────────────────────────────────

  void _handleArtifactAdded(dynamic data) {
    if (data is! Map || isOwner) return;

    final map = data.cast<String, dynamic>();
    if ((map['sessionId'] as String?) != sessionId) return;

    final artifactData = map['artifact'];
    if (artifactData == null) return;

    final savedArtefactId = artifactData['savedArtefactId'] as String?;
    final id = artifactData['id'] as String?;
    if (id == null) return;

    _log.fine(
        "RemoteSync => Received artifact added: $savedArtefactId (type: $id)");

    final boardItem = _createBoardArtifactFromData(
        artifactData, id, savedArtefactId ?? _generateSavedArtefactId());

    base.addArtifactToCurrentBoard(boardItem);
    notifyView();
  }

  void _handleArtifactRemoved(dynamic data) {
    if (data is! Map || isOwner) return;

    final map = data.cast<String, dynamic>();
    if ((map['sessionId'] as String?) != sessionId) return;

    final savedArtefactId = map['savedArtefactId'] as String?;
    if (savedArtefactId == null) return;

    _log.fine("RemoteSync => Received artifact removed: $savedArtefactId");

    if (base.showDirectional) {
      final artifacts = base.linearBoardController.artifacts;
      for (int i = artifacts.length - 1; i >= 0; i--) {
        if (artifacts[i]?.savedArtefactId == savedArtefactId) {
          base.linearBoardController.removeArtifact(i);
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
        notifyView();
        return;
      }
    }
    _log.fine(
        "RemoteSync => Artifact $savedArtefactId not found for removal");
  }

  void _handleArtifactMoved(dynamic data) {
    if (data is! Map || isOwner) return;

    final map = data.cast<String, dynamic>();
    if ((map['sessionId'] as String?) != sessionId) return;

    final savedArtefactId = map['savedArtefactId'] as String?;
    if (savedArtefactId == null) return;

    // Linear board index-based move
    final fromIndex = map['fromIndex'] as int?;
    final toIndex = map['toIndex'] as int?;

    if (base.showDirectional && fromIndex != null && toIndex != null) {
      int? actualFromIndex;
      for (int i = 0; i < base.linearBoardController.artifacts.length; i++) {
        if (base.linearBoardController.artifacts[i]?.savedArtefactId ==
            savedArtefactId) {
          actualFromIndex = i;
          break;
        }
      }

      if (actualFromIndex != null) {
        base.linearBoardController.moveArtifact(actualFromIndex, toIndex);
        notifyView();
      }
      return;
    }

    // TalkingMat position-based move
    final position = map['position'];
    if (position == null) return;

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

      base.talkingmatController.value = updatedArtifacts;
      notifyView();
    }
  }

  void _handleArtifactResized(dynamic data) {
    if (data is! Map || isOwner) return;

    final map = data.cast<String, dynamic>();
    if ((map['sessionId'] as String?) != sessionId) return;

    final savedArtefactId = map['savedArtefactId'] as String?;
    final size = map['size'];
    if (savedArtefactId == null || size == null) return;

    final newSize = Size(
      (size['width'] as num).toDouble(),
      (size['height'] as num).toDouble(),
    );

    if (base.showDirectional) {
      final artifacts = base.linearBoardController.artifacts
          .whereType<BoardArtefact>()
          .toList();
      final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
            (a) => a?.savedArtefactId == savedArtefactId,
            orElse: () => null,
          );
      if (artifact != null) {
        artifact.sizeNotifier.value = newSize;
        notifyView();
      }
    } else {
      final artifacts = base.talkingmatController.value;
      final artifact = artifacts.cast<BoardArtefact?>().firstWhere(
            (a) => a?.savedArtefactId == savedArtefactId,
            orElse: () => null,
          );
      if (artifact != null) {
        artifact.sizeNotifier.value = newSize;
        base.talkingmatController.value = List.from(artifacts);
        notifyView();
      }
    }
  }

  void _handleLayoutChanged(dynamic data) {
    if (data is! Map || isOwner) return;

    final map = data.cast<String, dynamic>();
    if ((map['sessionId'] as String?) != sessionId) return;

    final layout = map['layout'] as String?;
    if (layout == null) return;

    final directional = (layout == 'linear');
    if (base.showDirectional != directional) {
      base.switchCurrentBoard();
      notifyView();
    }
  }

  void _handleFieldCountChanged(dynamic data) {
    if (data is! Map || isOwner) return;

    final map = data.cast<String, dynamic>();
    if ((map['sessionId'] as String?) != sessionId) return;

    final count = map['count'] as int?;
    if (count == null) return;

    if (base.linearBoardController.fieldCount != count) {
      base.linearBoardController.setFieldCount(count);
      notifyView();
    }
  }

  // ── Private helpers ───────────────────────────────────────────

  /// Create a [BoardArtefact] from incoming SignalR data.
  BoardArtefact _createBoardArtifactFromData(
      dynamic data, String id, String? savedArtefactId) {
    final artefact = Artefact(
      artefactId: id,
      name: data['name'],
      imageUrl: _fixLocalhostUrl(data['imageUrl']),
      soundUrl: _fixLocalhostUrl(data['soundUrl']),
    );

    final token = GetIt.instance.get<Token>().value;
    Map<String, String>? headers;
    if (token != null) headers = {'Authorization': 'Bearer $token'};

    final boardItem = BoardArtefact.fromArtefact(artefact, headers: headers);
    boardItem.savedArtefactId = savedArtefactId;

    final size = data['size'];
    if (size != null) {
      boardItem.sizeNotifier.value = Size(
        (size['width'] as num).toDouble(),
        (size['height'] as num).toDouble(),
      );
    }

    final pos = data['position'];
    if (pos != null) {
      boardItem.position = Offset(
        (pos['dx'] as num).toDouble(),
        (pos['dy'] as num).toDouble(),
      );
    }

    return boardItem;
  }

  /// Update an existing artifact's position/size from incoming data.
  void _updateArtifactFromData(BoardArtefact existing, dynamic item) {
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
  }
}
