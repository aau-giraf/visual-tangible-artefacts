import 'package:signalr_netcore/signalr_client.dart';
import 'package:logging/logging.dart';


final _log = Logger('OnlineStatusTracker');
/// Tracks which users are currently online via the SignalR hub.
///
/// This class is an implementation detail of [SignalRService] and should
/// not be imported directly by widgets or other services.
class OnlineStatusTracker {
  final Set<String> _onlineUsers = {};

  Set<String> get onlineUsers => Set.unmodifiable(_onlineUsers);

  /// Check if a specific user is online.
  bool isUserOnline(String userId) => _onlineUsers.contains(userId);

  /// Get a snapshot of online user IDs.
  List<String> getOnlineUsers() => _onlineUsers.toList();

  /// Mark a user as online or offline (called from event handler).
  void setUserOnline(String userId, bool isOnline) {
    if (isOnline) {
      _onlineUsers.add(userId);
    } else {
      _onlineUsers.remove(userId);
    }
  }

  /// Fetch the full online-user set from the server.
  Future<void> refreshOnlineUsers(HubConnection hub) async {
    try {
      final result = await hub.invoke('GetOnlineUsers');
      if (result != null && result is List) {
        _onlineUsers.clear();
        for (var userId in result) {
          if (userId is String) _onlineUsers.add(userId);
        }
        _log.fine(
            '[SignalR] Refreshed online users: ${_onlineUsers.length} users online');
      }
    } catch (e) {
      _log.fine('[SignalR] Failed to refresh online users: $e');
    }
  }

  /// Clear all tracking state (called on disconnect).
  void clear() => _onlineUsers.clear();
}
