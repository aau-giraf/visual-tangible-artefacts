import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  static const String routeName = '/login';

  final AuthController controller;

  const LoginView({super.key, required this.controller});

  @override
  State<StatefulWidget> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final sharedUsernameController = TextEditingController();
  final sharedPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade100, Colors.white, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                minWidth: 300,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width > 600 
                    ? 400 
                    : MediaQuery.of(context).size.width * 0.85,
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width > 600 ? 32 : 24
                ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child:
                  _isLogin ? _loginForm(controller) : _signupForm(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm(AuthController controller) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Log ind',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: MediaQuery.of(context).size.width > 600 ? 28 : 24,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 32 : 24),
          TextFormField(
            controller: sharedUsernameController,
            decoration: InputDecoration(
              labelText: 'Brugernavn',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Indtast venligst dit brugernavn';
              }
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
          TextFormField(
            controller: sharedPasswordController,
            decoration: InputDecoration(
              labelText: 'Kodeord',
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Indtast venligst dit kodeord';
              }
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 32 : 24),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        _isLoading = true;
                      });
                      final username = sharedUsernameController.text;
                      final password = sharedPasswordController.text;
                      await controller.login(username, password,
                          context: context);
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(
                    color: Colors.white,
                  )
                : Text(
                    'Fortsæt',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isLogin = !_isLogin;
              });
            },
            child: Text(
              'Opret bruger',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signupForm(AuthController controller) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController guardianKeyController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Opret bruger',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: MediaQuery.of(context).size.width > 600 ? 28 : 24,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 32 : 24),
          TextFormField(
            controller: sharedUsernameController,
            decoration: InputDecoration(
              labelText: 'Brugernavn',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Indtast venligst et brugernavn';
              }
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
          TextFormField(
            controller: sharedPasswordController,
            decoration: InputDecoration(
              labelText: 'Kodeord',
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Indtast venligst et kodeord';
              }
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Navn',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Indtast venligst dit navn';
              }
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
          TextFormField(
            controller: guardianKeyController,
            decoration: InputDecoration(
              labelText: 'Værgenøgle',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Indtast venligst en værgenøgle';
              }
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 32 : 24),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        _isLoading = true;
                      });
                      final username = sharedUsernameController.text;
                      final password = sharedPasswordController.text;
                      final name = nameController.text;
                      final guardianKey = guardianKeyController.text;
                      await controller.signup(
                          username, password, name, guardianKey,
                          context: context);
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(
                    color: Colors.white,
                  )
                : Text(
                    'Opret bruger',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isLogin = !_isLogin;
              });
            },
            child: Text(
              'Har allerede en bruger? Log ind',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
