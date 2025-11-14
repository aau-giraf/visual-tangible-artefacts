import 'package:flutter/material.dart';
import 'package:vta_app/src/utilities/services/signalr_service.dart';

/// Component 1: CAREGIVER - "Request Shared Session"
/// Shows a list of children the caregiver can request sessions with
class CaregiverRequestWidget extends StatefulWidget {
  final String caregiverId;
  final List<ChildInfo> children; // List of children
  final Function(String sessionId, String childId) onSessionStarted;

  const CaregiverRequestWidget({
    Key? key,
    required this.caregiverId,
    required this.children,
    required this.onSessionStarted,
  }) : super(key: key);

  @override
  State<CaregiverRequestWidget> createState() => _CaregiverRequestWidgetState();
}

class _CaregiverRequestWidgetState extends State<CaregiverRequestWidget> {
  final SignalRService _signalR = SignalRService();
  bool _isConnecting = true;
  String? _pendingRequestToChildId;

  @override
  void initState() {
    super.initState();
    _initializeSignalR();
  }

  Future<void> _initializeSignalR() async {
    _signalR.onSessionRejected = () {
      if (mounted) {
        final childName = widget.children
            .firstWhere((c) => c.childId == _pendingRequestToChildId)
            .childName;
        setState(() => _pendingRequestToChildId = null);
        _showMessage(
          'Session Declined',
          '$childName is not ready to join right now.',
          Colors.orange,
          Icons.cancel_outlined,
        );
      }
    };

    _signalR.onSessionStarted = (sessionId) {
      if (mounted && _pendingRequestToChildId != null) {
        final childId = _pendingRequestToChildId!;
        setState(() => _pendingRequestToChildId = null);
        widget.onSessionStarted(sessionId, childId);
      }
    };

    try {
      await _signalR.connect(widget.caregiverId);
      setState(() => _isConnecting = false);
    } catch (e) {
      setState(() => _isConnecting = false);
      _showMessage(
        'Connection Error',
        'Failed to connect to server. Please try again.',
        Colors.red,
        Icons.error_outline,
      );
    }
  }

  Future<void> _requestSession(String childId, String childName) async {
    setState(() => _pendingRequestToChildId = childId);
    try {
      await _signalR.requestSession(childId);
      _showMessage(
        'Request Sent',
        'Waiting for $childName to accept...',
        Colors.blue,
        Icons.send,
      );
    } catch (e) {
      setState(() => _pendingRequestToChildId = null);
      _showMessage(
        'Request Failed',
        'Could not send request. Please try again.',
        Colors.red,
        Icons.error_outline,
      );
    }
  }

  void _showMessage(String title, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(message, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting...'),
          ],
        ),
      );
    }

    if (widget.children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No children connected',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start Online Session',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a child to collaborate with on the visual board',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // List of children
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.children.length,
            itemBuilder: (context, index) {
              final child = widget.children[index];
              final isPending = _pendingRequestToChildId == child.childId;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Child avatar
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          child.childName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Child info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.childName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.child_care, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Age ${child.age ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Call button
                      isPending
                          ? const SizedBox(
                              width: 50,
                              height: 50,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 3),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () => _requestSession(child.childId, child.childName),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Call',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Model for child information
class ChildInfo {
  final String childId;
  final String childName;
  final int? age;

  ChildInfo({
    required this.childId,
    required this.childName,
    this.age,
  });
}