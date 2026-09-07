import 'package:flutter/material.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/ui/screens/video_call_screen.dart';
import 'package:vta_app/src/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:logging/logging.dart';

final _log = Logger('CallManager');

// Manages incoming/outgoing call UI and navigation
class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  bool _isNavigatingToCall = false;
  bool _callbacksSetup = false;

  void setupCallbacks({bool force = false}) {
    if (_callbacksSetup && !force) {
      _log.fine('[CallManager] Callbacks already setup, skipping');
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
      _log.fine(
          '[CallManager] User $userId is ${isOnline ? "online" : "offline"}');
    };

    signalR.onMissedCall = (userId, userName) {
      _log.fine('[CallManager] Missed call from $userName');
    };

    _log.fine('[CallManager] Callbacks registered');
  }

  void clearCallbacks() {
    final signalR = SignalRService();
    signalR.onSessionRequested = null;
    signalR.onSessionStarted = null;
    signalR.onUserOnlineStatusChanged = null;
    signalR.onMissedCall = null;
    _callbacksSetup = false;
    _log.fine('[CallManager] Callbacks cleared');
  }

  void _showIncomingCallDialog(String fromUserId) async {
    _log.fine('_showIncomingCallDialog()');
    _log.fine('From User: $fromUserId');

    final context = MyApp.navigatorKey.currentContext;
    _log.fine('Context: ${context != null ? "Available" : "NULL"}');

    if (context == null) {
      _log.fine('ERROR: Cannot show dialog - context is NULL!');
      return;
    }

    final signalR = SignalRService();

    // Check if caller is in cache, if not refresh contacts
    String? callerName = signalR.getContactName(fromUserId);
    if (callerName == null) {
      _log.fine(
          '[CallManager] Caller $fromUserId not in cache, refreshing contacts');
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwtToken');
        if (token != null) {
          await signalR.loadContacts(token);
          callerName = signalR.getContactName(fromUserId);
        }
      } catch (e) {
        _log.fine('[CallManager] Failed to refresh contacts: $e');
      }
    }

    if (!context.mounted) return;

    final displayName = callerName ?? fromUserId;

    // Track if dialog was dismissed
    bool dialogDismissed = false;

    // Create a timer to auto-close after 30 seconds
    final autoCloseTimer = Timer(const Duration(seconds: 30), () {
      _log.fine('[CallManager] Auto-closing dialog after 30 seconds');
      if (!dialogDismissed && context.mounted) {
        dialogDismissed = true;
        Navigator.of(context, rootNavigator: true).pop();
        _log.fine('[CallManager] Dialog auto-closed');
      }
    });

    // Listen for MissedCall event to close dialog immediately
    void Function(String, String)? originalMissedCallHandler =
        signalR.onMissedCall;

    signalR.onMissedCall = (userId, userName) {
      _log.fine(
          '[CallManager] MissedCall received - closing dialog immediately');
      if (!dialogDismissed && context.mounted && userId == fromUserId) {
        dialogDismissed = true;
        autoCloseTimer.cancel();
        Navigator.of(context, rootNavigator: true).pop();
        _log.fine('[CallManager] Dialog closed due to MissedCall event');
      }
      // Call original handler (which shows notification)
      originalMissedCallHandler?.call(userId, userName);
    };

    if (!context.mounted) return;

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
                  Navigator.of(dialogCtx).pop();
                  _log.fine('[CallManager] Call rejected by user');
                  signalR.rejectSession(fromUserId);
                }
              },
              child: const Text("Afvis"),
            ),
            ElevatedButton(
              onPressed: () {
                if (!dialogDismissed) {
                  dialogDismissed = true;
                  autoCloseTimer.cancel();
                  signalR.onMissedCall = originalMissedCallHandler;
                  Navigator.of(dialogCtx).pop();
                  _log.fine('[CallManager] Call accepted by user');
                  final sessionId =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  signalR.acceptSession(
                    sessionId,
                    fromUserId,
                    signalR.currentUserId!,
                    SignalRService.defaultBoardId,
                  );
                  _navigateToVideoCall(
                      sessionId, SignalRService.defaultBoardId);
                }
              },
              child: const Text("Accepter"),
            ),
          ],
        );
      },
    ).then((_) {
      // Cleanup when dialog closes for any reason
      _log.fine('[CallManager] Dialog closed - cleaning up');
      autoCloseTimer.cancel();
      signalR.onMissedCall = originalMissedCallHandler;
    });
  }

  void _navigateToVideoCall(String sessionId, String boardId) {
    if (_isNavigatingToCall) return;
    _isNavigatingToCall = true;

    // Small delay to let the dialog close and UI settle
    Future.delayed(const Duration(milliseconds: 500), () {
      final navState = MyApp.navigatorKey.currentState;
      if (navState == null) {
        _log.fine('[CallManager] ERROR: No context available for navigation');
        _isNavigatingToCall = false;
        return;
      }

      final signalR = SignalRService();
      final currentUserId = signalR.currentUserId;
      final initiatorId = signalR.sessionInitiatorId;
      final remoteUserId = signalR.remoteUserId ?? 'unknown';
      bool isCaller = currentUserId == initiatorId;

      _log.fine(
          '[CallManager] Navigating to video call: sessionId=$sessionId, isCaller=$isCaller');

      navState
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
