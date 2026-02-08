import 'package:signalr_netcore/signalr_client.dart';
import 'package:vta_app/src/services/notification_service.dart';
import 'package:vta_app/src/services/online_status_tracker.dart';
import 'package:logging/logging.dart';


final _log = Logger('SignalrEventRouter');
/// Registers all SignalR `.on()` event handlers on the [HubConnection].
///
/// Callbacks are stored here so that [SignalRService] simply sets them
/// through this class. The router reads them when an event fires.
///
/// This class is an implementation detail of [SignalRService] and should
/// not be imported directly by widgets or other services.
class SignalREventRouter {
  final OnlineStatusTracker _statusTracker;

  SignalREventRouter(this._statusTracker);

  // ── Session callbacks ─────────────────────────────────────────

  void Function(String fromUserId)? onSessionRequested;
  void Function()? onSessionRejected;
  void Function(String sessionId, String boardId)? onSessionStarted;
  void Function(dynamic boardData)? onBoardUpdated;
  void Function()? onSessionEnded;

  // ── Online status callback ────────────────────────────────────

  void Function(String userId, bool isOnline)? onUserOnlineStatusChanged;

  // ── Delta update callbacks ────────────────────────────────────

  void Function(dynamic data)? onArtifactAdded;
  void Function(dynamic data)? onArtifactRemoved;
  void Function(dynamic data)? onArtifactMoved;
  void Function(dynamic data)? onArtifactResized;
  void Function(dynamic data)? onLayoutChanged;
  void Function(dynamic data)? onFieldCountChanged;

  // ── WebRTC signaling callbacks ────────────────────────────────

  void Function(String sessionId, Map<String, dynamic> offer)? onReceiveOffer;
  void Function(String sessionId, Map<String, dynamic> answer)? onReceiveAnswer;
  void Function(String sessionId, Map<String, dynamic> candidate)?
      onReceiveIceCandidate;

  // ── Missed call callback ──────────────────────────────────────

  void Function(String userId, String userName)? onMissedCall;

  // ── WebRTC message queues (buffered until callbacks wired) ────

  final List<Map<String, dynamic>> _pendingOffers = [];
  final List<Map<String, dynamic>> _pendingAnswers = [];
  final List<Map<String, dynamic>> _pendingIceCandidates = [];

  // ── State mutated by session events ───────────────────────────

  String? currentSessionId;
  String? sessionInitiatorId;
  String? remoteUserId;

  /// Contact cache for name resolution (userId → name).
  final Map<String, String> contactCache = {};

  /// Callback used to clear the owner board controller on session end.
  void Function()? onClearOwnerBoardController;

  // ── Public API ────────────────────────────────────────────────

  /// Register all `.on()` handlers on [hub].
  void registerEvents(HubConnection hub) {
    _log.fine('SignalR: Registering event handlers...');

    hub.on('SessionRequested', (args) {
      _log.fine('SignalR => Received SessionRequested event');
      if (args == null || args.isEmpty) return;
      final fromUserId = args[0] as String;
      remoteUserId = fromUserId;
      onSessionRequested?.call(fromUserId);
    });

    hub.on('SessionRejected', (_) {
      _log.fine('SignalR => Received SessionRejected event');
      onSessionRejected?.call();
    });

    hub.on('SessionStarted', (args) {
      _log.fine('SignalR => Received SessionStarted event');
      if (args == null || args.length < 2) return;
      currentSessionId = args[0] as String;
      final boardId = args[1] as String;
      onSessionStarted?.call(currentSessionId!, boardId);
    });

    hub.on('BoardUpdated', (args) {
      _log.fine('SignalR => Received BoardUpdated event');
      if (args == null || args.isEmpty) return;
      onBoardUpdated?.call(args[0]);
    });

    hub.on('SessionEnded', (_) {
      _log.fine('SignalR => Received SessionEnded event');
      currentSessionId = null;
      sessionInitiatorId = null;
      remoteUserId = null;
      onClearOwnerBoardController?.call();
      onSessionEnded?.call();
    });

    // Online status
    hub.on('UserOnlineStatusChanged', (args) {
      if (args == null || args.length < 2) return;
      final userId = args[0] as String;
      final isOnline = args[1] as bool;
      _log.fine(
          '[SignalR] UserOnlineStatusChanged: userId=$userId, isOnline=$isOnline');
      _statusTracker.setUserOnline(userId, isOnline);
      onUserOnlineStatusChanged?.call(userId, isOnline);
    });

    // WebRTC signaling
    hub.on('ReceiveOffer', (arguments) {
      final sessionId = arguments![0] as String;
      final offer = arguments[1] as Map<String, dynamic>;
      _log.fine('[SignalR] ReceiveOffer: sessionId=$sessionId');
      if (onReceiveOffer != null) {
        onReceiveOffer!(sessionId, offer);
      } else {
        _log.fine('[SignalR] Queuing offer (WebRTC service not ready yet)');
        _pendingOffers.add({'sessionId': sessionId, 'data': offer});
      }
    });

    hub.on('ReceiveAnswer', (arguments) {
      final sessionId = arguments![0] as String;
      final answer = arguments[1] as Map<String, dynamic>;
      _log.fine('[SignalR] ReceiveAnswer: sessionId=$sessionId');
      if (onReceiveAnswer != null) {
        onReceiveAnswer!(sessionId, answer);
      } else {
        _log.fine('[SignalR] Queuing answer (WebRTC service not ready yet)');
        _pendingAnswers.add({'sessionId': sessionId, 'data': answer});
      }
    });

    hub.on('ReceiveIceCandidate', (arguments) {
      final sessionId = arguments![0] as String;
      final candidate = arguments[1] as Map<String, dynamic>;
      _log.fine('[SignalR] ReceiveIceCandidate: sessionId=$sessionId');
      if (onReceiveIceCandidate != null) {
        onReceiveIceCandidate!(sessionId, candidate);
      } else {
        _log.fine(
            '[SignalR] Queuing ICE candidate (WebRTC service not ready yet)');
        _pendingIceCandidates
            .add({'sessionId': sessionId, 'data': candidate});
      }
    });

    // Delta update events
    hub.on('ArtifactAdded', (args) {
      _log.fine('SignalR => Received ArtifactAdded event');
      if (args == null || args.isEmpty) return;
      _log.fine('SignalR => Calling onArtifactAdded callback');
      onArtifactAdded?.call(args[0]);
    });

    hub.on('ArtifactRejected', (args) {
      _log.fine('SignalR => Received ArtifactRejected event');
      // TODO: Handle artifact rejection if needed
    });

    hub.on('ArtifactRemoved', (args) {
      _log.fine('SignalR => Received ArtifactRemoved event');
      if (args == null || args.isEmpty) return;
      _log.fine('SignalR => Calling onArtifactRemoved callback');
      onArtifactRemoved?.call(args[0]);
    });

    hub.on('ArtifactMoved', (args) {
      _log.fine('SignalR => Received ArtifactMoved event');
      if (args == null || args.isEmpty) return;
      _log.fine('SignalR => Calling onArtifactMoved callback');
      onArtifactMoved?.call(args[0]);
    });

    hub.on('ArtifactResized', (args) {
      _log.fine('SignalR => Received ArtifactResized event');
      if (args == null || args.isEmpty) return;
      _log.fine('SignalR => Calling onArtifactResized callback');
      onArtifactResized?.call(args[0]);
    });

    hub.on('LayoutChanged', (args) {
      _log.fine('SignalR => Received LayoutChanged event');
      if (args == null || args.isEmpty) return;
      _log.fine('SignalR => Calling onLayoutChanged callback');
      onLayoutChanged?.call(args[0]);
    });

    hub.on('FieldCountChanged', (args) {
      _log.fine('SignalR => Received FieldCountChanged event');
      if (args == null || args.isEmpty) return;
      _log.fine('SignalR => Calling onFieldCountChanged callback');
      onFieldCountChanged?.call(args[0]);
    });

    hub.on('MissedCall', (args) {
      _log.fine('SignalR => MissedCall EVENT');
      if (args == null || args.length < 2) {
        _log.fine('ERROR: Invalid MissedCall args!');
        return;
      }

      final fromUserId = args[0] as String;
      final fromUserNameFromBackend = args[1] as String;

      _log.fine('[SignalR] MissedCall from userId: $fromUserId');
      _log.fine('[SignalR] Name from backend: $fromUserNameFromBackend');

      final fromUserName =
          contactCache[fromUserId] ?? fromUserNameFromBackend;

      _log.fine('[SignalR] Final name to use: $fromUserName');

      NotificationService().showMissedCallNotification(fromUserName);
      onMissedCall?.call(fromUserId, fromUserName);
    });

    _log.fine('SignalR: All event handlers registered successfully');
  }

  /// Flush any buffered WebRTC messages to their callbacks.
  void flushWebRTCQueue() {
    _log.fine(
        '[SignalR] Flushing WebRTC queue: ${_pendingOffers.length} offers, '
        '${_pendingAnswers.length} answers, '
        '${_pendingIceCandidates.length} ICE candidates');

    for (var msg in _pendingOffers) {
      onReceiveOffer?.call(msg['sessionId'], msg['data']);
    }
    _pendingOffers.clear();

    for (var msg in _pendingAnswers) {
      onReceiveAnswer?.call(msg['sessionId'], msg['data']);
    }
    _pendingAnswers.clear();

    for (var msg in _pendingIceCandidates) {
      onReceiveIceCandidate?.call(msg['sessionId'], msg['data']);
    }
    _pendingIceCandidates.clear();
  }

  /// Clear all callbacks and queues (called on disconnect).
  void clear() {
    onSessionRequested = null;
    onSessionRejected = null;
    onSessionStarted = null;
    onBoardUpdated = null;
    onSessionEnded = null;
    onUserOnlineStatusChanged = null;
    onReceiveOffer = null;
    onReceiveAnswer = null;
    onReceiveIceCandidate = null;
    onMissedCall = null;
    onArtifactAdded = null;
    onArtifactRemoved = null;
    onArtifactMoved = null;
    onArtifactResized = null;
    onLayoutChanged = null;
    onFieldCountChanged = null;
    onClearOwnerBoardController = null;

    _pendingOffers.clear();
    _pendingAnswers.clear();
    _pendingIceCandidates.clear();

    contactCache.clear();

    currentSessionId = null;
    sessionInitiatorId = null;
    remoteUserId = null;
  }
}
