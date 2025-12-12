import 'package:flutter/material.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/ui/screens/video_call_screen.dart';
import 'package:vta_app/src/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Manages incoming/outgoing call UI and navigation
class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  bool _isNavigatingToCall = false;
  bool _callbacksSetup = false;

  void setupCallbacks({bool force = false}) {
    if (_callbacksSetup && !force) {
      debugPrint('[CallManager] Callbacks already setup, skipping');
      return;
    }
    _callbacksSetup = true;

    final signalR = SignalRService();

    signalR.onSessionRequested = (fromUserId) {
      _showIncomingCallDialog(fromUserId);
    };

    signalR.onSessionStarted = (sessionId, boardId) {
      _navigateToVideoCall(sessionId, boardId);
    };

    signalR.onUserOnlineStatusChanged = (userId, isOnline) {
      debugPrint(
          '[CallManager] User $userId is ${isOnline ? "online" : "offline"}');
    };

    signalR.onMissedCall = (userId, userName) {
      debugPrint('[CallManager] Missed call from $userName');
    };

    debugPrint('[CallManager] Callbacks registered');
  }

  void clearCallbacks() {
    final signalR = SignalRService();
    signalR.onSessionRequested = null;
    signalR.onSessionStarted = null;
    signalR.onUserOnlineStatusChanged = null;
    signalR.onMissedCall = null;
    _callbacksSetup = false;
    debugPrint('[CallManager] Callbacks cleared');
  }

  void _showIncomingCallDialog(String fromUserId) async {
    debugPrint('_showIncomingCallDialog()');
    debugPrint('From User: $fromUserId');

    final context = MyApp.navigatorKey.currentContext;
    debugPrint('Context: ${context != null ? "Available" : "NULL"}');

    if (context == null) {
      debugPrint('ERROR: Cannot show dialog - context is NULL!');
      return;
    }

    final signalR = SignalRService();

    // Check if caller is in cache, if not refresh contacts
    String? callerName = signalR.getContactName(fromUserId);
    if (callerName == null) {
      debugPrint(
          '[CallManager] Caller $fromUserId not in cache, refreshing contacts');
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

    // Track if dialog was dismissed
    bool dialogDismissed = false;

    // Create a timer to auto-close after 30 seconds
    final autoCloseTimer = Timer(const Duration(seconds: 30), () {
      debugPrint('[CallManager] Auto-closing dialog after 30 seconds');
      if (!dialogDismissed && context.mounted) {
        dialogDismissed = true;
        Navigator.of(context, rootNavigator: true).pop();
        debugPrint('[CallManager] Dialog auto-closed');
      }
    });

    // Listen for MissedCall event to close dialog immediately
    void Function(String, String)? originalMissedCallHandler =
        signalR.onMissedCall;

    signalR.onMissedCall = (userId, userName) {
      debugPrint(
          '[CallManager] MissedCall received - closing dialog immediately');
      if (!dialogDismissed && context.mounted && userId == fromUserId) {
        dialogDismissed = true;
        autoCloseTimer.cancel();
        Navigator.of(context, rootNavigator: true).pop();
        debugPrint('[CallManager] Dialog closed due to MissedCall event');
      }
      // Call original handler (which shows notification)
      originalMissedCallHandler?.call(userId, userName);
    };

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
                if (!dialogDismissed) {
                  dialogDismissed = true;
                  autoCloseTimer.cancel();
                  signalR.onMissedCall = originalMissedCallHandler;
                  signalR.rejectSession(fromUserId);
                  Navigator.of(dialogCtx).pop();
                  debugPrint('[CallManager] User rejected call');
                }
              },
              child: const Text("Afvis"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!dialogDismissed) {
                  dialogDismissed = true;
                  autoCloseTimer.cancel();
                  signalR.onMissedCall = originalMissedCallHandler;
                  Navigator.of(dialogCtx).pop();

                  final sessionId =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  await signalR.acceptSession(
                    sessionId,
                    fromUserId,
                    signalR.currentUserId!,
                    SignalRService.defaultBoardId,
                  );
                  debugPrint('[CallManager] User accepted call');
                }
              },
              child: const Text("Accepter"),
            ),
          ],
        );
      },
    ).then((_) {
      // Cleanup when dialog closes for any reason
      debugPrint('[CallManager] Dialog closed - cleaning up');
      autoCloseTimer.cancel();
      signalR.onMissedCall = originalMissedCallHandler;
    });
  }

  // Navigate to video call screen on session start
  void _navigateToVideoCall(String sessionId, String boardId) {
    if (_isNavigatingToCall) {
      debugPrint(
          '[CallManager] Already navigating to call, skipping duplicate');
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

      debugPrint(
          '[CallManager] Navigating to video call: sessionId=$sessionId, isCaller=$isCaller');

      Navigator.of(context)
          .pushAndRemoveUntil(
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
      )
          .then((_) {
        _isNavigatingToCall = false;
      });
    });
  }
}
