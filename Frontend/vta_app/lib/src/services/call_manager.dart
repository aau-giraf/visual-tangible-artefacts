import 'package:flutter/material.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/ui/screens/video_call_screen.dart';
import 'package:vta_app/src/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Manages incoming/outgoing call UI and navigation
class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  bool _isNavigatingToCall = false;

  void setupCallbacks() {
    final signalR = SignalRService();

    // Handle incoming call requests
    signalR.onSessionRequested = (fromUserId) {
      _showIncomingCallDialog(fromUserId);
    };

    // Handle session started
    signalR.onSessionStarted = (sessionId, boardId) {
      _navigateToVideoCall(sessionId, boardId);
    };

    debugPrint('[CallManager] Callbacks registered');
  }

  void clearCallbacks() {
    final signalR = SignalRService();
    signalR.onSessionRequested = null;
    signalR.onSessionStarted = null;
    debugPrint('[CallManager] Callbacks cleared');
  }

  void _showIncomingCallDialog(String fromUserId) async {
    final context = MyApp.navigatorKey.currentContext;
    if (context == null) return;

    final signalR = SignalRService();
    
    // Check if caller is in cache, if not refresh contacts
    String? callerName = signalR.getContactName(fromUserId);
    if (callerName == null) {
      debugPrint('[CallManager] Caller $fromUserId not in cache, refreshing contacts');
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwtToken');
        if (token != null) {
          await signalR.loadContacts(token);
          callerName = signalR.getContactName(fromUserId);
        }
      } catch (e) {
        debugPrint('[CallManager] Failed to refresh contacts: $e');
      }
    }
    
    final displayName = callerName ?? fromUserId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text("Indgående opkald"),
          content: Text("$displayName vil starte en fjernsession."),
          actions: [
            TextButton(
              onPressed: () {
                signalR.rejectSession(fromUserId);
                Navigator.of(dialogCtx).pop();
              },
              child: const Text("Afvis"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final sessionId =
                    DateTime.now().millisecondsSinceEpoch.toString();
                await signalR.acceptSession(
                  sessionId,
                  fromUserId,
                  signalR.currentUserId!,
                  SignalRService.defaultBoardId,
                );
              },
              child: const Text("Accepter"),
            ),
          ],
        );
      },
    );
  }

  // Navigate to video call screen on session start
  void _navigateToVideoCall(String sessionId, String boardId) {
    if (_isNavigatingToCall) {
      debugPrint('[CallManager] Already navigating to call, skipping duplicate');
      return;
    }

    _isNavigatingToCall = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      final context = MyApp.navigatorKey.currentContext;
      if (context == null) {
        debugPrint('[CallManager] ERROR: No context available for navigation');
        _isNavigatingToCall = false;
        return;
      }

      final signalR = SignalRService();
      final currentUserId = signalR.currentUserId;
      final initiatorId = signalR.sessionInitiatorId;
      final remoteUserId = signalR.remoteUserId ?? 'unknown';
      bool isCaller = currentUserId == initiatorId;

      debugPrint('[CallManager] Navigating to video call: sessionId=$sessionId, isCaller=$isCaller');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            hubConnection: signalR.hubConnection!,
            sessionId: sessionId,
            myUserId: currentUserId!,
            remoteUserId: remoteUserId,
            isCaller: isCaller,
          ),
        ),
        (route) => route.isFirst,
      ).then((_) {
        _isNavigatingToCall = false;
      });
    });
  }
}
