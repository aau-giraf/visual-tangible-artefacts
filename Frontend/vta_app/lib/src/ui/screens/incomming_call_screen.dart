import 'package:flutter/material.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:logging/logging.dart';


final _log = Logger('IncommingCallScreen');
/// Incoming call screen shown to CHILD when caregiver calls
/// Shows "Opkald fra `Caregiver Name`" with accept/decline buttons
class IncomingCallScreen extends StatefulWidget {
  static const String routeName = "/incoming-call";

  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late String caregiverId;
  late String caregiverName;
  late String childId;
  late AnimationController _pulseController;
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the call icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    // Listen for session start
    SignalRService().onSessionStarted = (sessionId, boardId) {
      _log.fine("IncomingCallScreen: onSessionStarted triggered with sessionId=$sessionId, boardId=$boardId");
      if (!mounted || _isResponding) return;
      
      // Navigate to active call
      Navigator.of(context).pushReplacementNamed(
        "/remote-board",
        arguments: {
          'sessionId': sessionId,
          'boardId': boardId,
        },
      );
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      caregiverId = args['caregiverId'] as String;
      caregiverName = args['caregiverName'] as String;
      childId = args['childId'] as String;
    }
  }

  Future<void> _acceptCall() async {
    if (_isResponding) return;
    
    _log.fine("IncomingCallScreen: _acceptCall started, caregiverId=$caregiverId, childId=$childId");
    
    setState(() {
      _isResponding = true;
    });

    try {
      // Use the default board for the call
      final boardId = SignalRService.defaultBoardId;
      
      final sessionId = '${DateTime.now().millisecondsSinceEpoch}_${caregiverId}_$childId';
      
      _log.fine("IncomingCallScreen: Calling acceptSession with sessionId=$sessionId, boardId=$boardId");
      
      await SignalRService().acceptSession(
        sessionId,
        caregiverId,
        childId,
        boardId,
      );
      
      _log.fine("IncomingCallScreen: acceptSession completed, waiting for onSessionStarted callback");
      
      // onSessionStarted callback will handle navigation
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResponding = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fejl ved accept af opkald: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineCall() async {
    if (_isResponding) return;
    
    setState(() {
      _isResponding = true;
    });

    try {
      await SignalRService().rejectSession(caregiverId);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResponding = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fejl ved afvisning af opkald: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
            colors: [Colors.green[600]!, Colors.green[800]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top section - caregiver info
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated phone icon with ripple effect
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple circles
                        ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 1.5).animate(
                            CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                            CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        // Phone icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_callback,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    
                    // "Opkald fra" text
                    const Text(
                      "Opkald fra",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Caregiver name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        caregiverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom section - action buttons
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: _isResponding
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Decline button
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: _declineCall,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(32),
                                  elevation: 8,
                                ),
                                child: const Icon(
                                  Icons.call_end,
                                  size: 44,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Afvis",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          // Accept button
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: _acceptCall,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[400],
                                  foregroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(32),
                                  elevation: 8,
                                ),
                                child: const Icon(
                                  Icons.call,
                                  size: 44,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Accepter",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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