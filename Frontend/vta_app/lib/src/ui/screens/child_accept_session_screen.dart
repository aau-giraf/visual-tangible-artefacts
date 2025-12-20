import 'package:flutter/material.dart';
import 'package:vta_app/src/services/signalr_service.dart';

/// Component 2: CHILD - Accept/Decline Session Popup
/// Pure popup notification card - no background, no scaffold
class ChildAcceptSessionScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final Function(String sessionId) onSessionAccepted;

  const ChildAcceptSessionScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.onSessionAccepted,
  });

  @override
  State<ChildAcceptSessionScreen> createState() =>
      _ChildAcceptSessionScreenState();
}

class _ChildAcceptSessionScreenState extends State<ChildAcceptSessionScreen> {
  final SignalRService _signalR = SignalRService();
  String? _pendingCaregiverRequest;
  String? _selectedBoardId; // Board to share when accepting

  @override
  void initState() {
    super.initState();
    _initializeSignalR();
  }

  Future<void> _initializeSignalR() async {
    _signalR.onSessionRequested = (caregiverUserId) {
      if (mounted) {
        setState(() {
          _pendingCaregiverRequest = caregiverUserId;
          // TODO: Show UI to let child select which board to share
          // For now, we'll need to set _selectedBoardId before accepting
        });
      }
    };

    _signalR.onSessionStarted = (sessionId, boardId) {
      if (mounted) {
        widget.onSessionAccepted(sessionId);
        setState(() {
          _pendingCaregiverRequest = null;
          _selectedBoardId = null;
        });
      }
    };

    try {
      await _signalR.connect(widget.childId);
    } catch (e) {
      debugPrint('Failed to connect to SignalR: $e');
    }
  }

  Future<void> _acceptSession() async {
    if (_pendingCaregiverRequest == null) return;

    // TODO: Before calling this, child should select which board to share
    // For now, using a placeholder - you need to implement board selection UI
    if (_selectedBoardId == null) {
      debugPrint('ERROR: No board selected to share');
      // You should show a board selection dialog here
      return;
    }

    final sessionId =
        '${DateTime.now().millisecondsSinceEpoch}_${_pendingCaregiverRequest}_${widget.childId}';

    try {
      await _signalR.acceptSession(
        sessionId,
        _pendingCaregiverRequest!,
        widget.childId,
        _selectedBoardId!,
      );
    } catch (e) {
      debugPrint('Failed to accept session: $e');
    }
  }

  Future<void> _rejectSession() async {
    if (_pendingCaregiverRequest == null) return;

    try {
      await _signalR.rejectSession(_pendingCaregiverRequest!);
      setState(() {
        _pendingCaregiverRequest = null;
      });
    } catch (e) {
      debugPrint('Failed to reject session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingCaregiverRequest == null) {
      return const SizedBox.shrink(); // Invisible when no request
    }

    // popup card
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[300]!, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Caregiver name
            Text(
              _pendingCaregiverRequest!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'vil gerne se dit board',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Decline
                Expanded(
                  child: SizedBox(
                    height: 70,
                    child: ElevatedButton(
                      onPressed: _rejectSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Icon(Icons.close, size: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Accept
                Expanded(
                  child: SizedBox(
                    height: 70,
                    child: ElevatedButton(
                      onPressed: _acceptSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[500],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Icon(Icons.check, size: 36),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
