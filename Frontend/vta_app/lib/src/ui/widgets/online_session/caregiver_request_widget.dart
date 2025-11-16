import 'package:flutter/material.dart';
import 'package:vta_app/src/utilities/services/signalr_service.dart';

/// Component 1: CAREGIVER - "Request Shared Session"
/// Sidebar with list of children the caregiver can request sessions with
class CaregiverRequestWidget extends StatefulWidget {
  final String caregiverId;
  final List<ChildInfo> children;
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
          'Afvist',
          '$childName er ikke klar lige nu.',
          Colors.orange,
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
      _showMessage('Fejl', 'Kunne ikke forbinde.', Colors.red);
    }
  }

  Future<void> _requestSession(String childId, String childName) async {
    setState(() => _pendingRequestToChildId = childId);
    try {
      await _signalR.requestSession(childId);
      _showMessage('Afsendt', 'Venter på $childName...', Colors.blue);
    } catch (e) {
      setState(() => _pendingRequestToChildId = null);
      _showMessage('Fejl', 'Kunne ikke sende anmodning.', Colors.red);
    }
  }

  void _showMessage(String title, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey[300]!, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-3, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              border: Border(
                bottom: BorderSide(color: Colors.blue[700]!, width: 2),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Online Session',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Vælg et barn at ringe til',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Loading state
          if (_isConnecting)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Forbinder...'),
                  ],
                ),
              ),
            ),

          // Empty state
          if (!_isConnecting && widget.children.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Ingen børn',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

          // List of children
          if (!_isConnecting && widget.children.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                itemCount: widget.children.length,
                itemBuilder: (context, index) {
                  final child = widget.children[index];
                  final isPending = _pendingRequestToChildId == child.childId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildChildCard(child, isPending),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChildCard(ChildInfo child, bool isPending) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? Colors.blue[400]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Child name
          Text(
            child.childName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (child.age != null) ...[
            const SizedBox(height: 4),
            Text(
              '${child.age} år',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Call button or loading
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isPending ? null : () => _requestSession(child.childId, child.childName),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending ? Colors.grey[300] : Colors.blue[600],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: isPending ? 0 : 2,
              ),
              child: isPending
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Venter...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ring op',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// child information
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