import 'package:get_it/get_it.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/platform_utils.dart';
import 'package:logging/logging.dart';


final _log = Logger('SignalrConnectionManager');
/// Owns the [HubConnection] lifecycle: build, connect, disconnect.
///
/// This class is an implementation detail of [SignalRService] and should
/// not be imported directly by widgets or other services.
class SignalRConnectionManager {
  HubConnection? _hubConnection;

  HubConnection? get hubConnection => _hubConnection;

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  /// Build and start the hub connection, returning the live [HubConnection].
  Future<HubConnection> connect() async {
    final hubUrl = _getHubUrl();
    _log.fine('SignalR: Connecting to $hubUrl');

    final jwtToken = GetIt.instance.get<Token>();

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
              accessTokenFactory: () async => jwtToken.value!),
        )
        .withAutomaticReconnect()
        .build();

    await _hubConnection!.start();
    _log.fine('SignalR: Connected');
    return _hubConnection!;
  }

  /// Stop and tear down the hub connection.
  Future<void> disconnect() async {
    try {
      await _hubConnection?.stop();
    } catch (e) { _log.fine('Error during SignalR disconnect: $e'); }
    _hubConnection = null;
    _log.fine('SignalR: Disconnected');
  }

  // ── Private helpers ───────────────────────────────────────────

  String _getHubUrl() {
    final baseUrl = PlatformUtils.getSyncServiceUrl();
    final normalizedUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$normalizedUrl/boardHub';
  }
}
