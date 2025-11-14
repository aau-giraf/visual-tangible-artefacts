import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  String? _currentUserId;
  String? _currentSessionId;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Function(String fromUserId)? onSessionRequested;
  Function()? onSessionRejected;
  Function(String sessionId)? onSessionStarted;
  Function(dynamic boardData)? onBoardUpdated;
  Function()? onSessionEnded;

  Future<void> connect(String userId) async {
    if (_hubConnection != null && isConnected) {
      debugPrint('Already connected to SignalR');
      return;
    }

    _currentUserId = userId;

    _hubConnection = HubConnectionBuilder()
        .withUrl('http://localhost:5002/boardHub')
        .withAutomaticReconnect()
        .build();

    _registerEventHandlers();

    try {
      await _hubConnection!.start();
      debugPrint('SignalR Connected');
      await _hubConnection!.invoke('RegisterUser', args: [userId]);
      debugPrint('User registered: $userId');
    } catch (e) {
      debugPrint('Error connecting to SignalR: $e');
      rethrow;
    }
  }

  void _registerEventHandlers() {
    _hubConnection!.on('SessionRequested', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        String fromUserId = arguments[0] as String;
        debugPrint('Session requested from caregiver: $fromUserId');
        onSessionRequested?.call(fromUserId);
      }
    });

    _hubConnection!.on('SessionRejected', (arguments) {
      debugPrint('Session rejected by child');
      onSessionRejected?.call();
    });

    _hubConnection!.on('SessionStarted', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        String sessionId = arguments[0] as String;
        _currentSessionId = sessionId;
        debugPrint('Session started: $sessionId');
        onSessionStarted?.call(sessionId);
      }
    });

    _hubConnection!.on('BoardUpdated', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        dynamic boardData = arguments[0];
        debugPrint('Board updated');
        onBoardUpdated?.call(boardData);
      }
    });

    _hubConnection!.on('SessionEnded', (arguments) {
      debugPrint('Session ended');
      _currentSessionId = null;
      onSessionEnded?.call();
    });
  }

  Future<void> requestSession(String childUserId) async {
    if (!isConnected) throw Exception('Not connected to SignalR');
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');
    try {
      await _hubConnection!.invoke('RequestSession', args: [userId, childUserId]);
      debugPrint('Session requested to child: $childUserId');
    } catch (e) {
      debugPrint('Error requesting session: $e');
      rethrow;
    }
  }

  Future<void> acceptSession(String sessionId, String caregiverUserId) async {
    if (!isConnected) throw Exception('Not connected to SignalR');
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');
    try {
      await _hubConnection!.invoke('AcceptSession', args: [sessionId, caregiverUserId, userId]);
      debugPrint('Session accepted: $sessionId');
    } catch (e) {
      debugPrint('Error accepting session: $e');
      rethrow;
    }
  }

  Future<void> rejectSession(String caregiverUserId) async {
    if (!isConnected) throw Exception('Not connected to SignalR');
    try {
      await _hubConnection!.invoke('RejectSession', args: [caregiverUserId]);
      debugPrint('Session rejected from: $caregiverUserId');
    } catch (e) {
      debugPrint('Error rejecting session: $e');
      rethrow;
    }
  }

  Future<void> updateBoard(dynamic boardData) async {
    if (!isConnected) throw Exception('Not connected to SignalR');
    final sessionId = _currentSessionId;
    if (sessionId == null) throw Exception('No active session');
    try {
      await _hubConnection!.invoke('UpdateBoard', args: [sessionId, boardData]);
      debugPrint('Board update sent');
    } catch (e) {
      debugPrint('Error updating board: $e');
      rethrow;
    }
  }

  Future<void> endSession() async {
    if (!isConnected) throw Exception('Not connected to SignalR');
    final sessionId = _currentSessionId;
    if (sessionId == null) throw Exception('No active session');
    try {
      await _hubConnection!.invoke('EndSession', args: [sessionId]);
      debugPrint('Session ended');
      _currentSessionId = null;
    } catch (e) {
      debugPrint('Error ending session: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
      _currentUserId = null;
      _currentSessionId = null;
      debugPrint('SignalR Disconnected');
    }
  }

  String? get currentSessionId => _currentSessionId;
  String? get currentUserId => _currentUserId;
}