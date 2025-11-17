import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';
import 'package:vta_app/src/modelsDTOs/signup_form.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:get_it/get_it.dart';

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
  UserRole _selectedRole = UserRole.child;

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
            child: Container(
              width: 400, // Set a fixed width for the box
              padding: EdgeInsets.all(32),
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
            'Log in',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 32),
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
          SizedBox(height: 16),
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
          SizedBox(height: 32),
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
          SizedBox(height: 16),
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
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Opret bruger',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 32),
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
          SizedBox(height: 16),
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
          SizedBox(height: 16),
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
          SizedBox(height: 16),
          DropdownButtonFormField<UserRole>(
            value: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Rolle',
            ),
            items: [
              DropdownMenuItem(
                value: UserRole.child,
                child: Text('Barn'),
              ),
              DropdownMenuItem(
                value: UserRole.caregiver,
                child: Text('caregiver?'),
              ),
            ],
            onChanged: (UserRole? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedRole = newValue;
                });
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Vælg venligst en rolle';
              }
              return null;
            },
          ),
          SizedBox(height: 32),
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

                      final signupForm = SignupForm(
                        username: username,
                        password: password,
                        name: name,
                        role: _selectedRole,
                      );
                      try {
                        final apiProvider = GetIt.instance.get<ApiProvider>();
                        final response = await apiProvider.postAsJson(
                          'Users/SignUp',
                          body: signupForm.toJson(),
                        );

                        if (response != null &&
                            (response.statusCode == 200 ||
                                response.statusCode == 201)) {
                          setState(() {
                            _isLogin = true;
                          });
                        } else {
                          throw Exception('Registration failed');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Fejl ved oprettelse af konto: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
          SizedBox(height: 16),
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
