import 'package:flutter/material.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'dart:async';

class CallingScreen extends StatefulWidget {
  static const String routeName = "/calling";

  const CallingScreen({super.key});

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen>
    with SingleTickerProviderStateMixin {
  String? childId;
  String? childName;
  bool _callInitiated = false;
  bool _isCallActive = true;
  bool _isDisposed = false;
  late AnimationController _pulseController;
  Timer? _timeoutTimer;

  // Store original callbacks
  void Function(String, String)? _originalOnSessionStarted;
  void Function()? _originalOnSessionRejected;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Get arguments and initiate call ONCE using post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_callInitiated && mounted) {
        _initializeCall();
      }
    });

    _setupSignalRListeners();
  }

  void _initializeCall() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    debugPrint('[CallingScreen] ═══════════════════════════════');
    debugPrint('[CallingScreen] Initializing call');
    debugPrint('[CallingScreen] Arguments: $args');

    if (args != null && !_callInitiated) {
      childId = args['childId'] as String;
      childName = args['childName'] as String;

      debugPrint('[CallingScreen] ✓ childId: $childId');
      debugPrint('[CallingScreen] ✓ childName: $childName');

      _callInitiated = true;
      _initiateCall();
    } else if (args == null) {
      debugPrint('[CallingScreen] ❌ ERROR: No arguments received!');
    }
    debugPrint('[CallingScreen] ═══════════════════════════════');
  }

  void _setupSignalRListeners() {
    final signalR = SignalRService();

    // Save existing callbacks
    _originalOnSessionStarted = signalR.onSessionStarted;
    _originalOnSessionRejected = signalR.onSessionRejected;

    // When session is rejected
    signalR.onSessionRejected = () {
      debugPrint('[CallingScreen] Call rejected');
      if (!_isDisposed && mounted && _isCallActive) {
        _timeoutTimer?.cancel();
        _showRejectionDialog();
      }
      _originalOnSessionRejected?.call();
    };

    // When session is accepted
    signalR.onSessionStarted = (sessionId, boardId) {
      debugPrint('[CallingScreen] Call accepted! SessionId: $sessionId');
      if (!_isDisposed && mounted && _isCallActive) {
        _timeoutTimer?.cancel();
        // Just pop - let CallManager handle navigation
        Navigator.of(context).pop();
      }
      _originalOnSessionStarted?.call(sessionId, boardId);
    };
  }

  Future<void> _initiateCall() async {
    if (_callInitiated && childId == null) {
      debugPrint('[CallingScreen] ERROR: childId is null!');
      return;
    }

    debugPrint('[CallingScreen] ═══ _initiateCall START ═══');
    debugPrint('[CallingScreen] childId: $childId');
    debugPrint(
        '[CallingScreen] SignalR.isConnected: ${SignalRService().isConnected}');

    try {
      debugPrint('[CallingScreen] Calling requestSession...');
      await SignalRService().requestSession(childId!);
      debugPrint('[CallingScreen] ✓ requestSession completed');

      // Set timeout (30 seconds)
      debugPrint('[CallingScreen] Starting 30-second timeout');
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        debugPrint('[CallingScreen] ⏰ Timeout reached!');
        if (mounted && _isCallActive && !_isDisposed) {
          _showTimeoutDialog();
        }
      });
    } catch (e) {
      debugPrint('[CallingScreen] ❌ ERROR: $e');
      if (!_isDisposed && mounted) {
        _showErrorDialog(e.toString());
      }
    }
    debugPrint('[CallingScreen] ═══ _initiateCall END ═══');
  }

  void _cancelCall() {
    debugPrint('[CallingScreen] User cancelled call');
    setState(() {
      _isCallActive = false;
    });
    _timeoutTimer?.cancel();
    Navigator.of(context).pop();
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Opkald afvist"),
        content: Text("${childName ?? 'Bruger'} afviste opkaldet."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Intet svar"),
        content: Text("${childName ?? 'Bruger'} svarede ikke på opkaldet."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Fejl"),
        content: Text("Kunne ikke starte opkald: $error"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pulseController.dispose();
    _timeoutTimer?.cancel();

    // Restore original callbacks
    final signalR = SignalRService();
    signalR.onSessionStarted = _originalOnSessionStarted;
    signalR.onSessionRejected = _originalOnSessionRejected;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[900]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_in_talk,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "Ringer til",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      childName ?? '...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _cancelCall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(28),
                        elevation: 8,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Annuller",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
