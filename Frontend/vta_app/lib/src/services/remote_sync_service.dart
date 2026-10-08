import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/modelsDTOs/board_update.dart';


/// RemoteSyncService manages the synchronization of board updates 
/// between clients in a collaborative session.
class RemoteSyncService {
  RemoteSyncService._();
  static final instance = RemoteSyncService._();

  final _signalR = SignalRService();


/// Starts the remote synchronization service for a given session.
  Future<void> start({
    required String sessionId,
    required Function(BoardUpdate update) onRemoteUpdate,
  }) async {
    _signalR.onBoardUpdated = (data) {
      if (data is Map<String, dynamic>) {
        onRemoteUpdate(BoardUpdate.fromJson(data));
      }
    };
  }

/// Sends a board update to the remote clients in the session.
  Future<void> sendUpdate(BoardUpdate update) async {
    await _signalR.updateBoard(update.toJson());
  }

/// Stops the remote synchronization service.
  Future<void> stop() async {
    await _signalR.endSession();
  }
}
