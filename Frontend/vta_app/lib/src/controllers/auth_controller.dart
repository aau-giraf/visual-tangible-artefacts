import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/models/auth_model.dart';
import 'package:vta_app/src/modelsDTOs/signup_form.dart';
import 'package:vta_app/src/shared/global_snackbar.dart';
import 'package:vta_app/src/ui/screens/artifact_board_screen.dart';
import 'package:vta_app/src/views/login_view.dart';

/// Used to control the authentication process and store authentication data
class AuthController extends ChangeNotifier {
  final AuthModel _model;
  final ArtefactController artifactController =
      GetIt.I.get<ArtefactController>();
  AuthController(this._model);

  // Checks if a valid token is stored in the device
  Future<bool> checkAuth({BuildContext? context}) async {
    var status = await _model.checkAuth();
    if (status) {
      await _model.loadCache();
    }
    return status;
  }

  /// Logs in the user with the provided [username] and [password]
  Future<void> login(String username, String password,
      {BuildContext? context}) async {
    try {
      await _model.login(username, password);

      if (context != null && context.mounted) {
        await artifactController.updateArtifacts(context: context);
        if(!context.mounted) return;
        await artifactController.updateMostUsedCategories(context: context);
        if(!context.mounted) return;
        Navigator.of(context)
            .pushReplacementNamed(ArtifactBoardScreen.routeName);
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    } finally {
      notifyListeners();
    }
  }

  /// Logs out the user and
  /// redirects to the login page given by [LoginView.routeName]
  ///
  /// Will only show the logout confirmation dialog if [context] is provided and mounted
  Future<void> logout(BuildContext? context) async {
    if (context != null && context.mounted) {
      await _showLogoutConfirmationDialog(context);
    } else {
      try {
        await artifactController.clearUserData();
        await _model.logout();
      } catch (e) {
        debugPrint('[AuthController.logout] clearUserData failed: $e');
      }
    }
    notifyListeners();
  }

  /// Signs up the user with the provided [email] and [password]
  Future<void> signup(
      String username, String password, String name, String guardianKey,
      {BuildContext? context}) async {
    try {
      var form = SignupForm(
          username: username,
          password: password,
          name: name,
          guardianKey: guardianKey);
      await _model.signup(form);
      if (context != null && context.mounted) {
        _showSuccessSnackBar(context, 'Bruger oprettet succesfuldt! Du kan nu logge ind.');
        // Switch back to login form
        Navigator.of(context).pushReplacementNamed(LoginView.routeName);
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    } finally {
      notifyListeners();
    }
  }

  /// Viser en dialog for at bekræfte udlogningen
  /// Omdirigerer til login siden givet af [LoginView.routeName]
  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log ud'),
          content: const Text('Er du sikker på, at du vil logge ud?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Annuller'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await artifactController.clearUserData();
                  await _model.logout();
                } catch (e) {
                  debugPrint(
                      '[AuthController.logout] clearUserData failed: $e');
                }
                if (!context.mounted) return;
                Navigator.of(context).pushReplacementNamed(LoginView.routeName);
              },
              child: const Text('Log ud'),
            ),
          ],
        );
      },
    );
  }

  /// Viser en snackbar med en fejl meddelelse
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    GlobalSnackbar.show(context, message,
        color: Colors.white, iconColor: Colors.red);
  }

  /// Viser en snackbar med en succes meddelelse
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    GlobalSnackbar.show(context, message,
        color: Colors.white, iconColor: Colors.green);
  }
}
