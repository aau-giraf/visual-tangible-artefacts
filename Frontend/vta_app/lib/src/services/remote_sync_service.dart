import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/modelsDTOs/board_update.dart';

class RemoteSyncService {
  RemoteSyncService._();
  static final instance = RemoteSyncService._();

  final _signalR = SignalRService();

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

  Future<void> sendUpdate(BoardUpdate update) async {
    await _signalR.updateBoard(update.toJson());
  }

  Future<void> stop() async {
    await _signalR.endSession();
  }
}
