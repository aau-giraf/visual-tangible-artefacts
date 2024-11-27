import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';
import 'package:vta_app/src/views/login_view.dart';

/// Just a functional placeholder for now.
///
/// Only checks if the jwt token is cached or not.
///
/// Could have more handling, like checking against a server.
class SplashView extends StatelessWidget {
  static const String routeName = '/';

  final AuthController controller;

  const SplashView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Used to wait for something to finish before continuing
    return FutureBuilder<bool>(
      future: controller.checkAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (snapshot.data == true) {
              Navigator.of(context)
                  .pushReplacementNamed('/home'); // not inplemented yet
            } else {
              Navigator.of(context).pushReplacementNamed(LoginView.routeName);
            }
          });
          return const Scaffold(
            body: Center(
              child: SizedBox.shrink(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: Text('Unexpected error'),
            ),
          );
        }
      },
    );
  }
}
