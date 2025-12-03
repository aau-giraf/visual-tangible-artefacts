// lib/src/services/signalr_service.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/singletons/token.dart';

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
  ArtifactBoardController? _ownerBoardController; // Store owner's board

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;
  String? get currentUserId => _currentUserId;
  String? get currentSessionId => _currentSessionId;
  String? get sessionInitiatorId => _sessionInitiatorId;

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

  // Callbacks
  void Function(String fromUserId)? onSessionRequested;
  void Function()? onSessionRejected;
  void Function(String sessionId, String boardId)? onSessionStarted;
  void Function(dynamic boardData)? onBoardUpdated;
  void Function()? onSessionEnded;

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
    const path = "/boardHub";
    if (kIsWeb) return "http://localhost:5002$path";
    if (Platform.isAndroid) return "http://10.0.2.2:5002$path";
    return "http://localhost:5002$path";
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
    _hubConnection!.on("SessionRequested", (args) {
      if (args == null || args.isEmpty) return;
      final fromUserId = args[0] as String;
      onSessionRequested?.call(fromUserId);
    });

    _hubConnection!.on("SessionRejected", (_) {
      onSessionRejected?.call();
    });

    _hubConnection!.on("SessionStarted", (args) {
      if (args == null || args.length < 2) return;
      _currentSessionId = args[0] as String;
      final boardId = args[1] as String;
      onSessionStarted?.call(_currentSessionId!, boardId);
    });

    _hubConnection!.on("BoardUpdated", (args) {
      if (args == null || args.isEmpty) return;
      onBoardUpdated?.call(args[0]);
    });

    _hubConnection!.on("SessionEnded", (_) {
      _currentSessionId = null;
      _sessionInitiatorId = null;
      _ownerBoardController = null;
      onSessionEnded?.call();
    });
  }

  // ---------------- API WRAPPERS ----------------
  Future<void> requestSession(String toUserId) async {
    if (!isConnected || _currentUserId == null) return;

    // Mark current user as the initiator
    _sessionInitiatorId = _currentUserId;

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

    _hubConnection = null;
    _currentUserId = null;
    _currentSessionId = null;
    _sessionInitiatorId = null;
    _ownerBoardController = null;
  }
}
