import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/board_controller.dart';
import 'package:vta_app/src/functions/loading_page.dart';
import 'package:vta_app/src/models/board_model.dart';
import 'package:vta_app/src/notifiers/vta_notifiers.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/artifact_board_screen.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatefulWidget {
  static const routeName = '/auth';

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final artifactState = Provider.of<ArtifactState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    BoardModel boardModel = BoardModel();
    BoardController boardController = BoardController(boardModel);
    if (await authState.loadTokenFromCache() &&
        await authState.loadUserIdFromCache()) {
      // Token is valid, navigate to user page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoadingPage(
            awaitCallbacks: [
              () async {
                return await userState.loadUser(authState.token!) &&
                    await boardController.loadCategories(authState.token!);
              },
            ],
            child: ArtifactBoardScreen(boardController: boardController),
          ),
        ),
      );
    } else {
      // Token is invalid or not present, navigate to login page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
