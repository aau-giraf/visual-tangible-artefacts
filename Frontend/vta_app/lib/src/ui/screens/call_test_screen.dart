import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:vta_app/src/ui/screens/video_call_screen.dart';
import 'package:vta_app/src/utilities/platform_utils.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:get_it/get_it.dart';

class CallTestScreen extends StatefulWidget {
  const CallTestScreen({Key? key}) : super(key: key);

  @override
  State<CallTestScreen> createState() => _CallTestScreenState();
}

class _CallTestScreenState extends State<CallTestScreen> {
  HubConnection? _hubConnection;
  String _status = 'Not connected';
  String _myUserId = '';
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _targetUserIdController = TextEditingController();
  String?  _incomingCallFrom;
  bool _isNavigatingToCall = false;
  
  // Pending session info - used to navigate after SessionStarted event
  String? _pendingSessionId;
  String? _pendingRemoteUserId;
  bool? _pendingIsCaller;

  @override
  void initState() {
    super.initState();
    _myUserId = GetIt.I. get<UserInfo>().userId ??  'user_${DateTime.now().millisecondsSinceEpoch}';
    _userIdController.text = _myUserId;
    _connectToSignalR();
  }

  Future<void> _connectToSignalR() async {
    try {
      setState(() => _status = 'Connecting.. .');
      
      final syncServiceUrl = '${PlatformUtils.getSyncServiceUrl()}/boardHub';
      final token = GetIt.I.get<Token>().value ??  '';
      
      print('[CallTest] Connecting to: $syncServiceUrl');
      print('[CallTest] User ID: $_myUserId');

      final httpConnectionOptions = HttpConnectionOptions(
        accessTokenFactory: () => Future.value(token),
        transport: HttpTransportType.WebSockets,
        skipNegotiation: true,
        logMessageContent: true,
      );

      _hubConnection = HubConnectionBuilder()
          .withUrl(syncServiceUrl, options: httpConnectionOptions)
          . withAutomaticReconnect(retryDelays: [0, 2000, 5000])
          .build();

      // Listen for incoming session requests
      _hubConnection! .on('SessionRequested', (arguments) {
        final fromUserId = arguments![0] as String;
        print('[CallTest] Incoming call from: $fromUserId');
        setState(() {
          _incomingCallFrom = fromUserId;
        });
        _showIncomingCallDialog(fromUserId);
      });

      // Listen for session started
      _hubConnection!.on('SessionStarted', (arguments) {
        final sessionId = arguments![0] as String;
        print('[CallTest] Session started: $sessionId');
        
        // Navigate to call screen now that the SignalR group is created
        if (_pendingSessionId != null && _pendingRemoteUserId != null && _pendingIsCaller != null) {
          print('[CallTest] Navigating to call screen as ${_pendingIsCaller! ? "caller" : "receiver"}');
          _navigateToCall(_pendingSessionId!, _pendingRemoteUserId!, isCaller: _pendingIsCaller!);
          // Clear pending session info
          _pendingSessionId = null;
          _pendingRemoteUserId = null;
          _pendingIsCaller = null;
        }
      });

      // Listen for session rejected
      _hubConnection!.on('SessionRejected', (arguments) {
        print('[CallTest] Call rejected');
        setState(() => _isNavigatingToCall = false);
        _pendingSessionId = null;
        _pendingRemoteUserId = null;
        _pendingIsCaller = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Call rejected')),
          );
        }
      });

      await _hubConnection!.start();
      await _hubConnection!.invoke('RegisterUser', args: [_myUserId]);
      
      setState(() => _status = 'Connected!');
      print('[CallTest] Connected and registered');
    } catch (e) {
      setState(() => _status = 'Error: $e');
      print('[CallTest] Connection error: $e');
    }
  }

  void _showIncomingCallDialog(String fromUserId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Incoming Call'),
        content: Text('$fromUserId is calling...'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _hubConnection! .invoke('RejectSession', args: [fromUserId]);
              setState(() => _incomingCallFrom = null);
            },
            child: Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isNavigatingToCall = true);
              final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
              
              // Store pending session info - will navigate when SessionStarted is received
              _pendingSessionId = sessionId;
              _pendingRemoteUserId = fromUserId;
              _pendingIsCaller = false;
              
              await _hubConnection!.invoke('AcceptSession', args: [
                sessionId,
                fromUserId,
                _myUserId,
                'board_123'  // Dummy board ID
              ]);
              // Don't navigate yet - wait for SessionStarted event
              print('[CallTest] Waiting for SessionStarted event...');
            },
            child: Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<void> _startCall() async {
    final targetUserId = _targetUserIdController.text.trim();
    if (targetUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter target user ID')),
      );
      return;
    }

    try {
      print('[CallTest] Requesting session with: $targetUserId');
      setState(() => _isNavigatingToCall = true);
      
      // Store pending session info - will navigate when SessionStarted is received
      // (after receiver accepts)
      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      _pendingSessionId = sessionId;
      _pendingRemoteUserId = targetUserId;
      _pendingIsCaller = true;
      
      await _hubConnection!.invoke('RequestSession', args: [_myUserId, targetUserId]);
      print('[CallTest] Waiting for receiver to accept...');
      // Don't navigate yet - wait for receiver to accept and SessionStarted event
    } catch (e) {
      print('[CallTest] Error starting call: $e');
      setState(() => _isNavigatingToCall = false);
      _pendingSessionId = null;
      _pendingRemoteUserId = null;
      _pendingIsCaller = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _navigateToCall(String sessionId, String remoteUserId, {required bool isCaller}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          hubConnection: _hubConnection! ,
          sessionId: sessionId,
          myUserId: _myUserId,
          remoteUserId: remoteUserId,
          isCaller: isCaller,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hubConnection?.stop();
    _userIdController.dispose();
    _targetUserIdController.dispose();
    _isNavigatingToCall = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _status.contains('Connected') ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Status: $_status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),

            // My User ID
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: 'My User ID',
                border: OutlineInputBorder(),
                enabled: false,
              ),
            ),
            SizedBox(height: 20),

            // Target User ID
            TextField(
              controller: _targetUserIdController,
              decoration: InputDecoration(
                labelText: 'Target User ID (to call)',
                border: OutlineInputBorder(),
                hintText: 'Enter user ID to call',
              ),
            ),
            SizedBox(height: 20),

            // Call Button
            ElevatedButton(
              onPressed: _status.contains('Connected') ? _startCall : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: Text(
                'Start Video Call',
                style: TextStyle(fontSize: 18),
              ),
            ),

            SizedBox(height: 40),

            // Instructions
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    '📱 Testing Instructions:\n\n'
                    '1. Open this screen on TWO devices/emulators\n'
                    '   - Note that those two devices cannot be both android emulators, nor does the windows app work\n\n'
                    '2.  Note your User ID on each device\n\n'
                    '3. On Device 1:\n'
                    '   - Enter Device 2\'s User ID\n'
                    '   - Press "Start Video Call"\n\n'
                    '4. On Device 2:\n'
                    '   - You\'ll get an incoming call popup\n'
                    '   - Press "Accept"\n\n'
                    '5. Both devices will connect!\n\n'
                    'Your User ID: $_myUserId',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}