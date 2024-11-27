import 'package:flutter/material.dart';
import 'package:vta_app/src/models/auth_model.dart';
import 'package:vta_app/src/shared/global_snackbar.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';

class AuthController extends ChangeNotifier {
  final AuthModel _model;

  AuthController(this._model);

  Future<bool> checkAuth({BuildContext? context}) async {
    return await _model.checkAuth();
  }

  Future<void> login(String username, String password,
      {BuildContext? context}) async {
    try {
      await _model.login(username, password);
    } catch (e) {
      if (context != null && context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    await _showLogoutConfirmationDialog(context);
    notifyListeners();
  }

  Future<void> signup(String email, String password,
      {BuildContext? context}) async {
    await _model.signup(email, password);
    notifyListeners();
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log ud'),
          content: const Text('Er du sikker på, at du vil logge ud?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuller'),
            ),
            TextButton(
              onPressed: () {
                _model.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Log ud'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    GlobalSnackbar.show(context, message,
        color: Colors.white, iconColor: Colors.red);
  }
}
