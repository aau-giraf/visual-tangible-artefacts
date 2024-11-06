import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/screens/error_screen.dart';

class LoadingPage extends StatelessWidget {
  final List<Future<bool> Function()> awaitCallbacks;
  final Widget child;

  const LoadingPage(
      {super.key, required this.awaitCallbacks, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _awaitCallbacks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return ErrorScreen(
              errorMessage: 'An error occured while loading page',
              onRetryChild: this);
        } else {
          return child; // Navigate to ArtifactBoardPage when data is loaded
        }
      },
    );
  }

  Future<void> _awaitCallbacks() async {
    for (var callback in awaitCallbacks) {
      if (!await callback()) {
        throw Exception("Failed while performing $callback");
      }
    }
  }
}
