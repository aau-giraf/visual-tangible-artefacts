import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/online_session/caregiver_request_widget.dart';
import 'package:vta_app/src/ui/screens/child_accept_session_screen.dart';
import 'package:vta_app/src/ui/screens/shared_board_screen.dart';

void main() => runApp(const ComponentViewer());

class ComponentViewer extends StatelessWidget {
  const ComponentViewer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VTA Component Viewer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ComponentViewerHome(),  // ← Only this line changed!
    );
  }
}

// Add this NEW class right after ComponentViewer:
class ComponentViewerHome extends StatelessWidget {
  const ComponentViewerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VTA Online Session Components')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select a Component to View',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 300,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Component1Demo()),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text(
                    'Component 1: Caregiver Request',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Component2Demo()),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text(
                    'Component 2: Child Accept',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

class Component1Demo extends StatelessWidget {
  const Component1Demo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Demo list of children
    final children = [
      ChildInfo(childId: 'child_emma', childName: 'Emma', age: 8),
      ChildInfo(childId: 'child_lucas', childName: 'Lucas', age: 10),
      ChildInfo(childId: 'child_sofia', childName: 'Sofia', age: 7),
      ChildInfo(childId: 'child_noah', childName: 'Noah', age: 9),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Component 1: Caregiver Request'),
        backgroundColor: Colors.blue,
      ),
      body: CaregiverRequestWidget(
        caregiverId: 'demo_caregiver',
        children: children,
        onSessionStarted: (sessionId, childId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Session started with $childId: $sessionId')),
          );
        },
      ),
    );
  }
}

class Component2Demo extends StatefulWidget {
  const Component2Demo({Key? key}) : super(key: key);

  @override
  State<Component2Demo> createState() => _Component2DemoState();
}

class _Component2DemoState extends State<Component2Demo> {
  bool _showIncomingRequest = false;

  @override
  void initState() {
    super.initState();
    // Simulate incoming request after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showIncomingRequest = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showIncomingRequest) {
      // Show the incoming request screen directly
      return _IncomingRequestDemo(
        childName: 'Emma',
        caregiverName: 'Anne (Voksen)',
      );
    }

    // Show waiting screen first
    return ChildAcceptSessionScreen(
      childId: 'demo_child',
      childName: 'Emma',
      onSessionAccepted: (sessionId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session accepted: $sessionId')),
        );
      },
    );
  }
}

// Direct incoming request demo
// Compact incoming request demo - corner notification
class _IncomingRequestDemo extends StatelessWidget {
  final String childName;
  final String caregiverName;

  const _IncomingRequestDemo({
    required this.childName,
    required this.caregiverName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barn - Accepter Session'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          // Main background (child's normal screen)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard, size: 120, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Hej, $childName!',
                  style: TextStyle(fontSize: 28, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Incoming request notification in corner
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caregiver name
                  Text(
                    caregiverName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'vil gerne se dit board',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Buttons row
                  Row(
                    children: [
                      // Decline button
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Afvist')),
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.close, size: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Accept button
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Accepteret!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[500],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.check, size: 32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
