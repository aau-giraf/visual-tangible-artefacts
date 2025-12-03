import 'package:flutter/material.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'dart:async';

/// Calling screen shown to CAREGIVER when they initiate a call
/// Shows "Ringer til <Child Name>..." with cancel button
class CallingScreen extends StatefulWidget {
  static const String routeName = "/calling";

  const CallingScreen({super.key});

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen>
    with SingleTickerProviderStateMixin {
  late String childId;
  late String childName;
  bool _isCallActive = true;
  late AnimationController _pulseController;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the phone icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Listen for session events
    _setupSignalRListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      childId = args['childId'] as String;
      childName = args['childName'] as String;
      
      // Send call request
      _initiateCall();
    }
  }

  void _setupSignalRListeners() {
    // When session is accepted
    SignalRService().onSessionStarted = (sessionId, boardId) {
      if (!mounted || !_isCallActive) return;
      
      _timeoutTimer?.cancel();
      
      // Navigate to active call screen
      Navigator.of(context).pushReplacementNamed(
        "/remote-board",
        arguments: {
          'sessionId': sessionId,
          'boardId': boardId,
        },
      );
    };

    // When session is rejected
    SignalRService().onSessionRejected = () {
      if (!mounted || !_isCallActive) return;
      
      _timeoutTimer?.cancel();
      
      _showRejectionDialog();
    };
  }

  Future<void> _initiateCall() async {
    try {
      await SignalRService().requestSession(childId);
      
      // Set timeout (30 seconds)
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && _isCallActive) {
          _showTimeoutDialog();
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _cancelCall() {
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
        content: Text("$childName afviste opkaldet."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close calling screen
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
        content: Text("$childName svarede ikke på opkaldet."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close calling screen
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
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close calling screen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timeoutTimer?.cancel();
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
              // Top section - child info
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated phone icon
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
                    
                    // "Ringer til..." text
                    const Text(
                      "Ringer til",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Child name
                    Text(
                      childName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Waiting indicator
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

              // Bottom section - cancel button
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    // Cancel button
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