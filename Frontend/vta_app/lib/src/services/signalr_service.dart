// lib/src/services/signalr_service.dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/data/data_repository.dart';
import 'package:vta_app/src/services/signalr_connection_manager.dart';
import 'package:vta_app/src/services/signalr_event_router.dart';
import 'package:vta_app/src/services/online_status_tracker.dart';

/// Singleton façade for the SignalR hub.
///
/// Delegates to:
/// * [SignalRConnectionManager] — connection lifecycle
/// * [SignalREventRouter]       — `.on()` handler registrations & callbacks
/// * [OnlineStatusTracker]      — online-user tracking
///
/// The public API is identical to the pre-split version so that all 16+
/// consumers require no import or call-site changes.
class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;

  SignalRService._internal()
      : _connectionManager = SignalRConnectionManager(),
        _statusTracker = OnlineStatusTracker() {
    _eventRouter = SignalREventRouter(_statusTracker);
    _eventRouter.onClearOwnerBoardController = () {
      _ownerBoardController = null;
    };
  }

  // WORKAROUND: Default board ID until multi-board support is implemented
  static const String defaultBoardId = 'default-shared-board';

  final SignalRConnectionManager _connectionManager;
  final OnlineStatusTracker _statusTracker;
  late final SignalREventRouter _eventRouter;

  String? _currentUserId;
  ArtifactBoardController? _ownerBoardController;

  // ── Getters (unchanged public surface) ────────────────────────

  bool get isConnected => _connectionManager.isConnected;
  String? get currentUserId => _currentUserId;
  String? get currentSessionId => _eventRouter.currentSessionId;
  String? get sessionInitiatorId => _eventRouter.sessionInitiatorId;
  String? get remoteUserId => _eventRouter.remoteUserId;
  get hubConnection => _connectionManager.hubConnection;
  Set<String> get onlineUsers => _statusTracker.onlineUsers;

  // ── Board controller storage ──────────────────────────────────

  void setOwnerBoardController(ArtifactBoardController controller) {
    _ownerBoardController = controller;
    debugPrint('SignalR: Stored owner board controller');
  }

  ArtifactBoardController? getOwnerBoardController() => _ownerBoardController;

  void clearOwnerBoardController() {
    _ownerBoardController = null;
  }

  // ── Online status (delegated) ─────────────────────────────────

  bool isUserOnline(String userId) => _statusTracker.isUserOnline(userId);
  List<String> getOnlineUsers() => _statusTracker.getOnlineUsers();
  Future<void> refreshOnlineUsers() async {
    if (!isConnected) return;
    await _statusTracker.refreshOnlineUsers(_connectionManager.hubConnection!);
  }

  // ── Contact cache (delegated) ─────────────────────────────────

  Future<void> loadContacts(String token) async {
    try {
      final contacts = await UserRepository().fetchRelatedContacts(token);
      if (contacts != null) {
        _eventRouter.contactCache.clear();
        for (var user in contacts) {
          final name =
              user.name?.isNotEmpty == true ? user.name! : user.username;
          _eventRouter.contactCache[user.id] = name;
        }
        debugPrint(
            'SignalR: Loaded ${_eventRouter.contactCache.length} contacts into cache');
      }
    } catch (e) {
      debugPrint('SignalR: Failed to load contacts => $e');
    }
  }

  String? getContactName(String userId) => _eventRouter.contactCache[userId];

  // ── WebRTC queue flush ────────────────────────────────────────

  void flushWebRTCQueue() => _eventRouter.flushWebRTCQueue();

  // ── Callback setters/getters (proxy to event router) ──────────

  // Session callbacks
  void Function(String)? get onSessionRequested =>
      _eventRouter.onSessionRequested;
  set onSessionRequested(void Function(String)? v) =>
      _eventRouter.onSessionRequested = v;

  void Function()? get onSessionRejected => _eventRouter.onSessionRejected;
  set onSessionRejected(void Function()? v) =>
      _eventRouter.onSessionRejected = v;

  void Function(String, String)? get onSessionStarted =>
      _eventRouter.onSessionStarted;
  set onSessionStarted(void Function(String, String)? v) =>
      _eventRouter.onSessionStarted = v;

  void Function(dynamic)? get onBoardUpdated => _eventRouter.onBoardUpdated;
  set onBoardUpdated(void Function(dynamic)? v) =>
      _eventRouter.onBoardUpdated = v;

  void Function()? get onSessionEnded => _eventRouter.onSessionEnded;
  set onSessionEnded(void Function()? v) => _eventRouter.onSessionEnded = v;

  // Online status callback
  void Function(String, bool)? get onUserOnlineStatusChanged =>
      _eventRouter.onUserOnlineStatusChanged;
  set onUserOnlineStatusChanged(void Function(String, bool)? v) =>
      _eventRouter.onUserOnlineStatusChanged = v;

  // Delta update callbacks
  void Function(dynamic)? get onArtifactAdded => _eventRouter.onArtifactAdded;
  set onArtifactAdded(void Function(dynamic)? v) =>
      _eventRouter.onArtifactAdded = v;

  void Function(dynamic)? get onArtifactRemoved =>
      _eventRouter.onArtifactRemoved;
  set onArtifactRemoved(void Function(dynamic)? v) =>
      _eventRouter.onArtifactRemoved = v;

  void Function(dynamic)? get onArtifactMoved => _eventRouter.onArtifactMoved;
  set onArtifactMoved(void Function(dynamic)? v) =>
      _eventRouter.onArtifactMoved = v;

  void Function(dynamic)? get onArtifactResized =>
      _eventRouter.onArtifactResized;
  set onArtifactResized(void Function(dynamic)? v) =>
      _eventRouter.onArtifactResized = v;

  void Function(dynamic)? get onLayoutChanged => _eventRouter.onLayoutChanged;
  set onLayoutChanged(void Function(dynamic)? v) =>
      _eventRouter.onLayoutChanged = v;

  void Function(dynamic)? get onFieldCountChanged =>
      _eventRouter.onFieldCountChanged;
  set onFieldCountChanged(void Function(dynamic)? v) =>
      _eventRouter.onFieldCountChanged = v;

  // WebRTC signaling callbacks
  void Function(String, Map<String, dynamic>)? get onReceiveOffer =>
      _eventRouter.onReceiveOffer;
  set onReceiveOffer(void Function(String, Map<String, dynamic>)? v) =>
      _eventRouter.onReceiveOffer = v;

  void Function(String, Map<String, dynamic>)? get onReceiveAnswer =>
      _eventRouter.onReceiveAnswer;
  set onReceiveAnswer(void Function(String, Map<String, dynamic>)? v) =>
      _eventRouter.onReceiveAnswer = v;

  void Function(String, Map<String, dynamic>)? get onReceiveIceCandidate =>
      _eventRouter.onReceiveIceCandidate;
  set onReceiveIceCandidate(
          void Function(String, Map<String, dynamic>)? v) =>
      _eventRouter.onReceiveIceCandidate = v;

  // Missed call callback
  void Function(String, String)? get onMissedCall =>
      _eventRouter.onMissedCall;
  set onMissedCall(void Function(String, String)? v) =>
      _eventRouter.onMissedCall = v;

  // ── CONNECT ───────────────────────────────────────────────────

  Future<void> connect(String userId) async {
    if (isConnected) return;

    _currentUserId = userId;
    debugPrint('SignalR: Connecting as user=$userId');

    try {
      final hub = await _connectionManager.connect();

      // Load contacts from API before registering
      final token = GetIt.instance.get<Token>().value!;
      await loadContacts(token);

      _eventRouter.registerEvents(hub);
      await _registerUser();
      await refreshOnlineUsers();
    } catch (e) {
      debugPrint('SignalR: Connection failed → $e');
      rethrow;
    }
  }

  // ── Session API wrappers ──────────────────────────────────────

  Future<void> requestSession(String toUserId) async {
    if (!isConnected || _currentUserId == null) return;
    _eventRouter.sessionInitiatorId = _currentUserId;
    _eventRouter.remoteUserId = toUserId;
    await _connectionManager.hubConnection!.invoke(
      'RequestSession',
      args: <Object>[_currentUserId!, toUserId],
    );
    debugPrint('SignalR: requestSession => $_currentUserId → $toUserId');
  }

  Future<void> acceptSession(String sessionId, String fromUserId,
      String toUserId, String boardId) async {
    if (!isConnected || _currentUserId == null) return;
    final actualBoardId =
        boardId == 'placeholder-board-id' ? defaultBoardId : boardId;
    _eventRouter.sessionInitiatorId = fromUserId;
    await _connectionManager.hubConnection!.invoke(
      'AcceptSession',
      args: <Object>[sessionId, fromUserId, toUserId, actualBoardId],
    );
    debugPrint(
        'SignalR: acceptSession => $sessionId from $fromUserId to $toUserId with boardId=$actualBoardId');
  }

  Future<void> rejectSession(String fromUserId) async {
    if (!isConnected) return;
    await _connectionManager.hubConnection!
        .invoke('RejectSession', args: <Object>[fromUserId]);
  }

  Future<void> updateBoard(dynamic boardData) async {
    if (!isConnected || _eventRouter.currentSessionId == null) return;
    await _connectionManager.hubConnection!.invoke(
      'UpdateBoard',
      args: <Object>[_eventRouter.currentSessionId!, boardData],
    );
  }

  // ── Delta update API wrappers ─────────────────────────────────

  Future<void> sendArtifactAdded(dynamic data) async {
    if (!isConnected || _eventRouter.currentSessionId == null) return;
    await _connectionManager.hubConnection!
        .invoke('ArtifactAdded', args: <Object>[data]);
  }

  Future<void> sendArtifactRemoved(dynamic data) async {
    if (!isConnected || _eventRouter.currentSessionId == null) return;
    await _connectionManager.hubConnection!
        .invoke('ArtifactRemoved', args: <Object>[data]);
  }

  Future<void> sendArtifactMoved(dynamic data) async {
    if (!isConnected || _eventRouter.currentSessionId == null) return;
    await _connectionManager.hubConnection!
        .invoke('ArtifactMoved', args: <Object>[data]);
  }

  Future<void> sendArtifactResized(dynamic data) async {
    if (!isConnected || _eventRouter.currentSessionId == null) return;
    await _connectionManager.hubConnection!
        .invoke('ArtifactResized', args: <Object>[data]);
  }

  Future<void> sendLayoutChanged(dynamic data) async {
    if (!isConnected || _eventRouter.currentSessionId == null) return;
    await _connectionManager.hubConnection!
        .invoke('LayoutChanged', args: <Object>[data]);
  }

  Future<void> sendFieldCountChanged(dynamic data) async {
    if (!isConnected || _eventRouter.currentSessionId == null) return;
    await _connectionManager.hubConnection!
        .invoke('FieldCountChanged', args: <Object>[data]);
  }

  Future<void> endSession() async {
    if (!isConnected || _eventRouter.currentSessionId == null) return;
    await _connectionManager.hubConnection!
        .invoke('EndSession', args: <Object>[_eventRouter.currentSessionId!]);
    _eventRouter.currentSessionId = null;
    _eventRouter.sessionInitiatorId = null;
  }

  // ── DISCONNECT ────────────────────────────────────────────────

  Future<void> disconnect() async {
    await _connectionManager.disconnect();

    _currentUserId = null;
    _ownerBoardController = null;

    _statusTracker.clear();
    _eventRouter.clear();

    debugPrint('SignalR: All state and callbacks cleared');
  }

  // ── Private helpers ───────────────────────────────────────────

  Future<void> _registerUser() async {
    if (_currentUserId == null) return;
    try {
      final contactIds = _eventRouter.contactCache.keys.toList();
      await _connectionManager.hubConnection!
          .invoke('RegisterUser', args: <Object>[_currentUserId!, contactIds]);
      debugPrint(
          'SignalR: Registered user $_currentUserId with ${contactIds.length} contacts');
    } catch (e) {
      debugPrint('SignalR: RegisterUser ERROR → $e');
    }
  }
}
