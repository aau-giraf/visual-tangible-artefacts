import 'package:flutter/material.dart';
import 'package:vta_app/src/utilities/services/signalr_service.dart';

/// Component 2: CHILD - "Accept Session" Screen
/// Large, autism-friendly interface for child to accept caregiver's request
class ChildAcceptSessionScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final Function(String sessionId) onSessionAccepted;

  const ChildAcceptSessionScreen({
    Key? key,
    required this.childId,
    required this.childName,
    required this.onSessionAccepted,
  }) : super(key: key);

  @override
  State<ChildAcceptSessionScreen> createState() => _ChildAcceptSessionScreenState();
}

class _ChildAcceptSessionScreenState extends State<ChildAcceptSessionScreen>
    with SingleTickerProviderStateMixin {
  final SignalRService _signalR = SignalRService();
  bool _isConnecting = true;
  String? _pendingCaregiverRequest;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initializeSignalR();
  }

  Future<void> _initializeSignalR() async {
    _signalR.onSessionRequested = (caregiverUserId) {
      if (mounted) {
        setState(() {
          _pendingCaregiverRequest = caregiverUserId;
        });
      }
    };

    _signalR.onSessionStarted = (sessionId) {
      if (mounted) {
        widget.onSessionAccepted(sessionId);
      }
    };

    try {
      await _signalR.connect(widget.childId);
      setState(() {
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });
      _showMessage('Kunne ikke forbinde. Bed om hjælp.', Colors.red);
    }
  }

  Future<void> _acceptSession() async {
    if (_pendingCaregiverRequest == null) return;

    final sessionId = '${DateTime.now().millisecondsSinceEpoch}_${_pendingCaregiverRequest}_${widget.childId}';

    try {
      await _signalR.acceptSession(sessionId, _pendingCaregiverRequest!);
    } catch (e) {
      _showMessage('Kunne ikke starte session. Prøv igen.', Colors.red);
    }
  }

  Future<void> _rejectSession() async {
    if (_pendingCaregiverRequest == null) return;

    try {
      await _signalR.rejectSession(_pendingCaregiverRequest!);
      setState(() {
        _pendingCaregiverRequest = null;
      });
      _showMessage('Anmodning afvist', Colors.grey);
    } catch (e) {
      _showMessage('Kunne ikke afvise. Bed om hjælp.', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barn - Accepter Session'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: _isConnecting
            ? _buildLoadingState()
            : _pendingCaregiverRequest != null
                ? _buildRequestScreen()
                : _buildWaitingState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 6),
          const SizedBox(height: 32),
          Text(
            'Gør klar...',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard,
              size: 120,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 32),
            Text(
              'Hej, ${widget.childName}!',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '"Artifact board"',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestScreen() {
    return Container(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.visibility,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),

            // Message
            Text(
              '$_pendingCaregiverRequest vil gerne se dit board!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Vil du dele dit board?',
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 64),

            // Accept button - Large and friendly
            SizedBox(
              width: double.infinity,
              height: 120,
              child: ElevatedButton(
                onPressed: _acceptSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[500],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 56),
                    const SizedBox(height: 8),
                    const Text(
                      'JA, Del Mit Board',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Decline button - More prominent
            SizedBox(
              width: double.infinity,
              height: 100,
              child: ElevatedButton(
                onPressed: _rejectSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, size: 40),
                    SizedBox(width: 12),
                    Text(
                      'NEJ, Ikke Nu',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}