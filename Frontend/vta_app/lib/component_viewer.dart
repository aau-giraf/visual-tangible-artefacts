import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/online_session/caregiver_request_widget.dart';
import 'package:vta_app/src/ui/screens/child_accept_session_screen.dart';


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
    final children = [
      ChildInfo(childId: 'child_1', childName: 'Child 1', age: 8),
      ChildInfo(childId: 'child_2', childName: 'Child 2', age: 10),
      ChildInfo(childId: 'child_3', childName: 'Child 3', age: 7),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Component 1: Caregiver Request Sidebar'),
        backgroundColor: Colors.blue,
      ),
      body: Align(
        alignment: Alignment.centerRight,
        child: CaregiverRequestWidget(
          caregiverId: 'demo_caregiver',
          children: children,
          onSessionStarted: (sessionId, childId) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Session started with $childId: $sessionId'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }
}
class Component2Demo extends StatelessWidget {
  const Component2Demo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Component 2: Child Accept Popup'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: _DemoPopup(),
      ),
    );
  }
}

// Popup widget
class _DemoPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Anne (Voksen)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'vil gerne se dit board',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Afvist'), backgroundColor: Colors.red),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.close, size: 36, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accepteret!'), backgroundColor: Colors.green),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[500],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.check, size: 36, color: Colors.white),
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