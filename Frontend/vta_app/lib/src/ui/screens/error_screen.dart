import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final Widget onRetryChild;

  const ErrorScreen({super.key, this.errorMessage, required this.onRetryChild});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(builder: (context) {
                return onRetryChild;
              })),
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(Colors.blue)),
              child: Text(
                'Try again',
                style: TextStyle(color: Colors.black),
              ),
            )
          ],
        ),
      ),
    );
  }
}
