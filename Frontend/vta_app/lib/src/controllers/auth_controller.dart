import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/models/auth_model.dart';
import 'package:vta_app/src/modelsDTOs/signup_form.dart';
import 'package:vta_app/src/shared/global_snackbar.dart';
import 'package:vta_app/src/ui/screens/welcome_screen.dart';
import 'package:vta_app/src/ui/screens/artifact_board_screen.dart';
import 'package:vta_app/src/ui/screens/remote_session_screen.dart';
import 'package:vta_app/src/views/login_view.dart';
import 'package:vta_app/src/services/sync_timer.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/services/call_manager.dart';
import 'package:vta_app/src/modelsDTOs/user.dart' as user_model;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';


final _log = Logger('AuthController');
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
      SyncTimer().start();

      // Connect to SignalR and setup callbacks if already authenticated
      final userId = _model.userInfo.userId;
      if (userId != null && userId.isNotEmpty) {
        try {
          await SignalRService().connect(userId);

          // Load contacts cache and setup call UI callbacks
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwtToken');
          if (token != null) {
            await SignalRService().loadContacts(token);
          }
          CallManager().setupCallbacks();

          _log.fine(
              "SignalR: connected & registered user $userId (from checkAuth)");
        } catch (e) {
          _log.fine("SignalR: connect failed in checkAuth => $e");
        }
      }
    }
    return status;
  }

  /// Logs in the user with the provided [username] and [password]
  Future<void> login(String username, String password,
      {BuildContext? context}) async {
    try {
      await _model.login(username, password);

      if (context != null && context.mounted) {
        _showSuccessSnackBar(context, 'Login succesfuldt! Velkommen tilbage.');
        await artifactController.updateArtifacts(context: context);
        if (!context.mounted) return;
        await artifactController.updateMostUsedCategories(context: context);
        if (!context.mounted) return;
        final userId = _model.userInfo.userId;
        if (userId != null && userId.isNotEmpty) {
          try {
            await SignalRService().connect(userId);

            // Load contacts cache and setup call UI callbacks
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('jwtToken');
            if (token != null) {
              await SignalRService().loadContacts(token);
            }
            CallManager().setupCallbacks();

            _log.fine("SignalR: connected & registered user $userId");
          } catch (e) {
            _log.fine("SignalR: connect failed => $e");
          }
        } else {
          _log.fine("WARNING: No userId available for SignalR connection");
        }
        if (!context.mounted) return;

        if (userId != null) {
          final user = await _model.getUser(userId);
          if (user != null && user.role == user_model.UserRole.caregiver) {
            Navigator.of(context)
                .pushReplacementNamed(RemoteSessionScreen.routeName);
            return;
          }
        }

        Navigator.of(context).pushReplacementNamed(WelcomeScreen.routeName);
      }
    } catch (e) {
      _log.fine('[AUTH] Error: ${e.toString()}');
      // Re-throw the exception so LoginView can catch and display it
      // LoginView displays errors inline to prevent keyboard issues
      rethrow;
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
        // Clear call callbacks
        CallManager().clearCallbacks();

        // Disconnect from SignalR
        await SignalRService().disconnect();

        // Clear all user data
        await artifactController.clearUserData();
        await _model.logout();

        _log.fine('[AuthController.logout] Logout complete');
      } catch (e) {
        _log.fine('[AuthController.logout] clearUserData failed: $e');
      }
    }
    notifyListeners();
  }

  /// Signs up the user with the provided [username], [password], and [name]
  Future<void> signup(String username, String password, String name,
      {BuildContext? context}) async {
    try {
      var form = SignupForm(username: username, password: password, name: name);
      await _model.signup(form);
      if (context != null && context.mounted) {
        _showSuccessSnackBar(
            context, 'Bruger oprettet succesfuldt! Du kan nu logge ind.');
        // Switch back to login form
        Navigator.of(context).pushReplacementNamed(LoginView.routeName);
      }

      // If successful, navigate to main screen
      // if (context != null && context.mounted) {
      //   await artifactController.updateArtifacts(context: context);
      //   if(!context.mounted) return;
      //   await artifactController.updateMostUsedCategories(context: context);
      //   if(!context.mounted) return;
      //   Navigator.of(context)
      //       .pushReplacementNamed(ArtifactBoardScreen.routeName);
      //   }
    } catch (e) {
      _log.fine('[AUTH] Signup Error: ${e.toString()}');
      // Re-throw the exception so LoginView can catch and display it
      // LoginView displays errors inline to prevent keyboard issues
      rethrow;
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
                  // Clear call callbacks
                  CallManager().clearCallbacks();

                  // Disconnect from SignalR
                  await SignalRService().disconnect();

                  // Clear all user data
                  await artifactController.clearUserData();
                  await _model.logout();

                  _log.fine('[AuthController.logout] Logout complete');
                } catch (e) {
                  _log.fine(
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

  /// Gets the current user based on the stored user ID
  Future<user_model.User?> getCurrentUser() async {
    final userId = _model.userInfo.userId;
    if (userId != null && userId.isNotEmpty) {
      return await _model.getUser(userId);
    }
    return null;
  }

  /// Viser en snackbar med en succes meddelelse
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    GlobalSnackbar.show(context, message,
        color: Colors.white, iconColor: Colors.green);
  }
}
