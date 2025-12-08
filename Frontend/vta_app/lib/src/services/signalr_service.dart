// lib/src/services/signalr_service.dart

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/platform_utils.dart';
import 'package:vta_app/src/utilities/data/data_repository.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  // WORKAROUND: Default board ID until multi-board support is implemented
  static const String defaultBoardId = "default-shared-board";

  HubConnection? _hubConnection;
  String? _currentUserId;
  String? _currentSessionId;
  String? _sessionInitiatorId; // Track who started the session
  String? _remoteUserId;
  ArtifactBoardController? _ownerBoardController; // Store owner's board
  
  // Contact cache for name resolution (userId -> name)
  final Map<String, String> _contactCache = {};
  
  // WebRTC signaling message queues
  final List<Map<String, dynamic>> _pendingOffers = [];
  final List<Map<String, dynamic>> _pendingAnswers = [];
  final List<Map<String, dynamic>> _pendingIceCandidates = [];
  
  // WebRTC signaling callbacks
  void Function(String sessionId, Map<String, dynamic> offer)? onReceiveOffer;
  void Function(String sessionId, Map<String, dynamic> answer)? onReceiveAnswer;
  void Function(String sessionId, Map<String, dynamic> candidate)? onReceiveIceCandidate;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;
  String? get currentUserId => _currentUserId;
  String? get currentSessionId => _currentSessionId;
  String? get sessionInitiatorId => _sessionInitiatorId;
  String? get remoteUserId => _remoteUserId;
  HubConnection? get hubConnection => _hubConnection;

  // Board controller storage for remote sessions
  void setOwnerBoardController(ArtifactBoardController controller) {
    _ownerBoardController = controller;
    debugPrint("SignalR: Stored owner board controller");
  }

  ArtifactBoardController? getOwnerBoardController() {
    return _ownerBoardController;
  }

  void clearOwnerBoardController() {
    _ownerBoardController = null;
  }
  
  // Contact cache management
  /// Load contacts from API and cache them for name resolution
  Future<void> loadContacts(String token) async {
    try {
      final contacts = await UserRepository().fetchRelatedContacts(token);
      
      if (contacts != null) {
        _contactCache.clear();
        for (var user in contacts) {
          final name = user.name?.isNotEmpty == true ? user.name! : user.username;
          _contactCache[user.id] = name;
        }
        debugPrint('SignalR: Loaded ${_contactCache.length} contacts into cache');
      }
    } catch (e) {
      debugPrint('SignalR: Failed to load contacts => $e');
    }
  }
  
  /// Get contact name from cache, returns null if not found
  String? getContactName(String userId) {
    return _contactCache[userId];
  }
  
  void flushWebRTCQueue() {
    debugPrint('[SignalR] Flushing WebRTC queue: ${_pendingOffers.length} offers, ${_pendingAnswers.length} answers, ${_pendingIceCandidates.length} ICE candidates');
    
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
  
  // Callbacks
  void Function(String fromUserId)? onSessionRequested;
  void Function()? onSessionRejected;
  void Function(String sessionId, String boardId)? onSessionStarted;
  void Function(dynamic boardData)? onBoardUpdated;
  void Function()? onSessionEnded;
  
  // Delta update callbacks
  void Function(dynamic data)? onArtifactAdded;
  void Function(dynamic data)? onArtifactRemoved;
  void Function(dynamic data)? onArtifactMoved;
  void Function(dynamic data)? onArtifactResized;
  void Function(dynamic data)? onLayoutChanged;

  // ---------------- CONNECT ----------------
  Future<void> connect(String userId) async {
    if (isConnected) return;

    _currentUserId = userId;
    final hubUrl = _getHubUrl();
    debugPrint("SignalR: Connecting to $hubUrl as user=$userId");
    var jwtToken = GetIt.instance.get<Token>();
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
              accessTokenFactory: () async => jwtToken.value!),
        )
        .withAutomaticReconnect()
        .build();

    _registerEvents();

    try {
      await _hubConnection!.start();
      debugPrint("SignalR: Connected");
      await _registerUser();
    } catch (e) {
      debugPrint("SignalR: Connection failed → $e");
      rethrow;
    }
  }

  // Determine URL based on platform
  String _getHubUrl() {
    final baseUrl = PlatformUtils.getSyncServiceUrl();
    return "$baseUrl/boardHub";
  }

  Future<void> _registerUser() async {
    if (_currentUserId == null) return;
    try {
      await _hubConnection!
          .invoke("RegisterUser", args: <Object>[_currentUserId!]);
      debugPrint("SignalR: Registered user $_currentUserId");
    } catch (e) {
      debugPrint("SignalR: RegisterUser ERROR → $e");
    }
  }

  // ---------------- EVENT HANDLERS ----------------
  void _registerEvents() {
    debugPrint("SignalR: Registering event handlers...");
    
    _hubConnection!.on("SessionRequested", (args) {
      debugPrint("SignalR => Received SessionRequested event");
      if (args == null || args.isEmpty) return;
      final fromUserId = args[0] as String;
      _remoteUserId = fromUserId;
      onSessionRequested?.call(fromUserId);
    });

    _hubConnection!.on("SessionRejected", (_) {
      debugPrint("SignalR => Received SessionRejected event");
      onSessionRejected?.call();
    });

    _hubConnection!.on("SessionStarted", (args) {
      debugPrint("SignalR => Received SessionStarted event");
      if (args == null || args.length < 2) return;
      _currentSessionId = args[0] as String;
      final boardId = args[1] as String;
      onSessionStarted?.call(_currentSessionId!, boardId);
    });

    _hubConnection!.on("BoardUpdated", (args) {
      debugPrint("SignalR => Received BoardUpdated event");
      if (args == null || args.isEmpty) return;
      onBoardUpdated?.call(args[0]);
    });

    _hubConnection!.on("SessionEnded", (_) {
      debugPrint("SignalR => Received SessionEnded event");
      _currentSessionId = null;
      _sessionInitiatorId = null;
      _remoteUserId = null;
      _ownerBoardController = null;
      onSessionEnded?.call();
    });
    
    // WebRTC signaling listeners
    _hubConnection!.on('ReceiveOffer', (arguments) {
      final sessionId = arguments![0] as String;
      final offer = arguments[1] as Map<String, dynamic>;
      debugPrint('[SignalR] ReceiveOffer: sessionId=$sessionId');
      
      if (onReceiveOffer != null) {
        onReceiveOffer!(sessionId, offer);
      } else {
        debugPrint('[SignalR] Queuing offer (WebRTC service not ready yet)');
        _pendingOffers.add({'sessionId': sessionId, 'data': offer});
      }
    });
    
    _hubConnection!.on('ReceiveAnswer', (arguments) {
      final sessionId = arguments![0] as String;
      final answer = arguments[1] as Map<String, dynamic>;
      debugPrint('[SignalR] ReceiveAnswer: sessionId=$sessionId');
      
      if (onReceiveAnswer != null) {
        onReceiveAnswer!(sessionId, answer);
      } else {
        debugPrint('[SignalR] Queuing answer (WebRTC service not ready yet)');
        _pendingAnswers.add({'sessionId': sessionId, 'data': answer});
      }
    });
    
    _hubConnection!.on('ReceiveIceCandidate', (arguments) {
      final sessionId = arguments![0] as String;
      final candidate = arguments[1] as Map<String, dynamic>;
      debugPrint('[SignalR] ReceiveIceCandidate: sessionId=$sessionId');
      
      if (onReceiveIceCandidate != null) {
        onReceiveIceCandidate!(sessionId, candidate);
      } else {
        debugPrint('[SignalR] Queuing ICE candidate (WebRTC service not ready yet)');
        _pendingIceCandidates.add({'sessionId': sessionId, 'data': candidate});
      }
    });

    // Delta update events
    _hubConnection!.on("ArtifactAdded", (args) {
      debugPrint("SignalR => Received ArtifactAdded event");
      if (args == null || args.isEmpty) return;
      debugPrint("SignalR => Calling onArtifactAdded callback");
      onArtifactAdded?.call(args[0]);
    });

    _hubConnection!.on("ArtifactRemoved", (args) {
      debugPrint("SignalR => Received ArtifactRemoved event");
      if (args == null || args.isEmpty) return;
      debugPrint("SignalR => Calling onArtifactRemoved callback");
      onArtifactRemoved?.call(args[0]);
    });

    _hubConnection!.on("ArtifactMoved", (args) {
      debugPrint("SignalR => Received ArtifactMoved event");
      if (args == null || args.isEmpty) return;
      debugPrint("SignalR => Calling onArtifactMoved callback");
      onArtifactMoved?.call(args[0]);
    });

    _hubConnection!.on("ArtifactResized", (args) {
      debugPrint("SignalR => Received ArtifactResized event");
      if (args == null || args.isEmpty) return;
      debugPrint("SignalR => Calling onArtifactResized callback");
      onArtifactResized?.call(args[0]);
    });

    _hubConnection!.on("LayoutChanged", (args) {
      debugPrint("SignalR => Received LayoutChanged event");
      if (args == null || args.isEmpty) return;
      debugPrint("SignalR => Calling onLayoutChanged callback");
      onLayoutChanged?.call(args[0]);
    });
    
    // Handle connection closed - if in an active session, end it
    _hubConnection!.on("Closed", (args) {
      debugPrint("SignalR: Connection closed");
      if (_currentSessionId != null) {
        debugPrint("SignalR: Active session detected - ending session due to connection loss");
        // Clear session state
        _currentSessionId = null;
        _sessionInitiatorId = null;
        _remoteUserId = null;
        _ownerBoardController = null;
        // Notify UI that session has ended
        onSessionEnded?.call();
      }
    });
    
    debugPrint("SignalR: All event handlers registered successfully");
  }

  // ---------------- API WRAPPERS ----------------
  Future<void> requestSession(String toUserId) async {
    if (!isConnected || _currentUserId == null) return;

    // Mark current user as the initiator
    _sessionInitiatorId = _currentUserId;
    _remoteUserId = toUserId;

    await _hubConnection!.invoke(
      "RequestSession",
      args: <Object>[_currentUserId!, toUserId],
    );
    debugPrint("SignalR: requestSession => $_currentUserId → $toUserId");
  }

  Future<void> acceptSession(
      String sessionId, String fromUserId, String toUserId, String boardId) async {
    if (!isConnected || _currentUserId == null) return;

    // WORKAROUND: Use default board ID until multi-board support is implemented
    final actualBoardId = boardId == "placeholder-board-id" ? defaultBoardId : boardId;

    // Mark the one who initiated as the initiator
    _sessionInitiatorId = fromUserId;

    await _hubConnection!.invoke(
      "AcceptSession",
      args: <Object>[sessionId, fromUserId, toUserId, actualBoardId],
    );
    debugPrint(
        "SignalR: acceptSession => $sessionId from $fromUserId to $toUserId with boardId=$actualBoardId");
  }

  Future<void> rejectSession(String fromUserId) async {
    if (!isConnected) return;
    await _hubConnection!.invoke("RejectSession", args: <Object>[fromUserId]);
  }

  Future<void> updateBoard(dynamic boardData) async {
    if (!isConnected || _currentSessionId == null) return;
    await _hubConnection!.invoke(
      "UpdateBoard",
      args: <Object>[_currentSessionId!, boardData],
    );
  }

  // ---------------- DELTA UPDATE API WRAPPERS ----------------
  
  Future<void> sendArtifactAdded(dynamic data) async {
    if (!isConnected || _currentSessionId == null) return;
    await _hubConnection!.invoke("ArtifactAdded", args: <Object>[data]);
  }

  Future<void> sendArtifactRemoved(dynamic data) async {
    if (!isConnected || _currentSessionId == null) return;
    await _hubConnection!.invoke("ArtifactRemoved", args: <Object>[data]);
  }

  Future<void> sendArtifactMoved(dynamic data) async {
    if (!isConnected || _currentSessionId == null) return;
    await _hubConnection!.invoke("ArtifactMoved", args: <Object>[data]);
  }

  Future<void> sendArtifactResized(dynamic data) async {
    if (!isConnected || _currentSessionId == null) return;
    await _hubConnection!.invoke("ArtifactResized", args: <Object>[data]);
  }

  Future<void> sendLayoutChanged(dynamic data) async {
    if (!isConnected || _currentSessionId == null) return;
    await _hubConnection!.invoke("LayoutChanged", args: <Object>[data]);
  }

  Future<void> endSession() async {
    if (!isConnected || _currentSessionId == null) return;
    await _hubConnection!
        .invoke("EndSession", args: <Object>[_currentSessionId!]);
    _currentSessionId = null;
    _sessionInitiatorId = null;
  }

  // ---------------- DISCONNECT ----------------
  Future<void> disconnect() async {
    try {
      await _hubConnection?.stop();
    } catch (_) {}
    debugPrint("SignalR: Disconnected");

    // Clear all state
    _hubConnection = null;
    _currentUserId = null;
    _currentSessionId = null;
    _sessionInitiatorId = null;
    _remoteUserId = null;
    _ownerBoardController = null;
    
    // Clear all callbacks
    onSessionRequested = null;
    onSessionRejected = null;
    onSessionStarted = null;
    onBoardUpdated = null;
    onSessionEnded = null;
    
    // Clear WebRTC callbacks
    onReceiveOffer = null;
    onReceiveAnswer = null;
    onReceiveIceCandidate = null;
    
    // Clear message queues
    _pendingOffers.clear();
    _pendingAnswers.clear();
    _pendingIceCandidates.clear();
    
    // Clear contact cache
    _contactCache.clear();
    
    debugPrint("SignalR: All state and callbacks cleared");
  }
}
