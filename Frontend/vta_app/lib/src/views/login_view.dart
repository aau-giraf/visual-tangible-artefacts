// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';
import 'package:vta_app/src/modelsDTOs/signup_form.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';

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
  final TextEditingController nameController = TextEditingController();
  final TextEditingController guardianKeyController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _loginErrorMessage;
  String? _signupErrorMessage;

  UserRole _selectedRole = UserRole.child;

  @override
  void dispose() {
    sharedUsernameController.dispose();
    sharedPasswordController.dispose();
    nameController.dispose();
    guardianKeyController.dispose();
    super.dispose();
  }

  /// Translates error messages to Danish
  String translateErrorToDanish(String error) {
    // Remove 'Exception: ' prefix if present
    if (error.startsWith('Exception: ')) {
      error = error.substring(11);
    }

    // Translate common error messages to Danish
    switch (error.toLowerCase()) {
      case 'invalid username or password':
        return 'Ugyldigt brugernavn eller adgangskode';
      case 'this username already exists, please choose another':
        return 'Dette brugernavn eksisterer allerede, vælg venligst et andet';
      case 'no response from server':
        return 'Ingen respons fra serveren';
      case 'a server error occured':
        return 'Der opstod en serverfejl';
      case 'an unknown error occured':
        return 'Der opstod en ukendt fejl';
      default:
        // If no translation found, return the original error
        return error;
    }
  }

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
                    MediaQuery.of(context).size.width > 600 ? 32 : 24),
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
                    _isLogin ? loginForm(controller) : _signupForm(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget loginForm(AuthController controller) {
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
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
            onChanged: (_) {
              if (_loginErrorMessage != null) {
                setState(() {
                  _loginErrorMessage = null;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Indtast venligst dit brugernavn';
              }
              if (value.trim().length < 3) {
                return 'Brugernavn skal være mindst 3 tegn';
              }
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
          TextFormField(
            controller: sharedPasswordController,
            decoration: InputDecoration(
              labelText: 'Kodeord',
              prefixIcon: Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
            obscureText: _obscurePassword,
            onChanged: (_) {
              if (_loginErrorMessage != null) {
                setState(() {
                  _loginErrorMessage = null;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Indtast venligst dit kodeord';
              }
              return null;
            },
          ),
          if (_loginErrorMessage != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loginErrorMessage!,
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 32 : 24),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (formKey.currentState!.validate()) {
                      if (!mounted) return;
                      setState(() {
                        _isLoading = true;
                        _loginErrorMessage = null;
                      });
                      try {
                        final username = sharedUsernameController.text.trim();
                        final password = sharedPasswordController.text;
                        await controller.login(username, password,
                            context: context);
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            // Use the translation helper we kept earlier
                            _loginErrorMessage =
                                translateErrorToDanish(e.toString());
                          });
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Fortsæt',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isLogin = !_isLogin;
                _loginErrorMessage = null;
                _signupErrorMessage = null;
                sharedPasswordController.clear();
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
    bool obscureSignupPassword = true;

    // Password strength calculation
    String? getPasswordStrength(String password) {
      if (password.isEmpty) return null;
      int strength = 0;
      if (password.length >= 6) strength++;
      if (password.length >= 8) strength++;
      if (password.contains(RegExp(r'[A-Z]'))) strength++;
      if (password.contains(RegExp(r'[a-z]'))) strength++;
      if (password.contains(RegExp(r'[0-9]'))) strength++;
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

      if (strength <= 2) return 'Svagt';
      if (strength <= 4) return 'Mellem';
      return 'Stærkt';
    }

    Color? getPasswordStrengthColor(String password) {
      final strength = getPasswordStrength(password);
      if (strength == null) return null;
      if (strength == 'Svagt') return Colors.red;
      if (strength == 'Mellem') return Colors.orange;
      return Colors.green;
    }

    return StatefulBuilder(
      builder: (context, setState) => Form(
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
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red),
                ),
                helperText: 'Mindst 3 tegn',
              ),
              onChanged: (_) {
                // Error will be cleared on form submission
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Indtast venligst et brugernavn';
                }
                final trimmed = value.trim();
                if (trimmed.length < 3) {
                  return 'Brugernavn skal være mindst 3 tegn';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
                  return 'Brugernavn kan kun indeholde bogstaver, tal og underscore';
                }
                return null;
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
            TextFormField(
              controller: sharedPasswordController,
              decoration: InputDecoration(
                labelText: 'Kodeord',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureSignupPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureSignupPassword = !obscureSignupPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red),
                ),
                helperText: sharedPasswordController.text.isNotEmpty
                    ? 'Styrke: ${getPasswordStrength(sharedPasswordController.text)}'
                    : null,
                helperMaxLines: 2,
              ),
              obscureText: obscureSignupPassword,
              onChanged: (_) {
                setState(() {}); // Update password strength indicator
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Indtast venligst et kodeord';
                }
                // Commented out for flexibility, maybe re-enable if Emil/ Egebakken thinks it's needed
                // if (value.length < 6) {
                //   return 'Kodeord skal være mindst 6 tegn';
                // }
                return null;
              },
            ),
            if (sharedPasswordController.text.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LinearProgressIndicator(
                  value: getPasswordStrength(sharedPasswordController.text) ==
                          'Svagt'
                      ? 0.33
                      : getPasswordStrength(sharedPasswordController.text) ==
                              'Mellem'
                          ? 0.66
                          : 1.0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    getPasswordStrengthColor(sharedPasswordController.text) ??
                        Colors.grey,
                  ),
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Navn',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              onChanged: (_) {
                // Error will be cleared on form submission
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Indtast venligst dit navn';
                }
                if (value.trim().length < 2) {
                  return 'Navn skal være mindst 2 tegn';
                }
                return null;
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
            DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Rolle',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: UserRole.child,
                  child: Text('Barn / Bruger'),
                ),
                DropdownMenuItem(
                  value: UserRole.caregiver,
                  child: Text('Pædagog / Værge'),
                ),
              ],
              onChanged: (UserRole? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
            TextFormField(
              controller: guardianKeyController,
              decoration: InputDecoration(
                labelText: 'Værgenøgle',
                prefixIcon: Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Indtast venligst en værgenøgle';
                }
                return null;
              },
            ),
            if (_signupErrorMessage != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _signupErrorMessage!,
                        style:
                            TextStyle(color: Colors.red.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).size.width > 600 ? 32 : 24),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        final parentState =
                            context.findAncestorStateOfType<_LoginViewState>();

                        // Helper to update state in parent or local
                        void updateState(VoidCallback fn) {
                          if (parentState != null && parentState.mounted) {
                            parentState.setState(fn);
                          } else if (mounted) {
                            setState(fn);
                          }
                        }

                        updateState(() {
                          _isLoading = true;
                          _signupErrorMessage = null;
                        });

                        try {
                          final username = sharedUsernameController.text.trim();
                          final password = sharedPasswordController.text;
                          final name = nameController.text.trim();

                          final signupForm = SignupForm(
                            username: username,
                            password: password,
                            name: name,
                            role: _selectedRole,
                            // guardianKey: guardianKeyController.text.trim(), // Add if model supports it
                          );

                          final apiProvider = GetIt.instance.get<ApiProvider>();
                          final response = await apiProvider.postAsJson(
                            'Users/SignUp',
                            body: signupForm.toJson(),
                          );

                          if (response != null &&
                              (response.statusCode == 200 ||
                                  response.statusCode == 201)) {
                            // Success - switch to login
                            updateState(() {
                              _isLogin = true;
                              _signupErrorMessage = null;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Bruger oprettet! Log ind nu.')),
                              );
                            });
                          } else {
                            throw Exception(
                                'Registration failed: ${response?.statusCode}');
                          }
                        } catch (e) {
                          updateState(() {
                            _signupErrorMessage =
                                translateErrorToDanish(e.toString());
                          });
                        } finally {
                          updateState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade400,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Opret bruger',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
            TextButton(
              onPressed: () {
                final parentState =
                    context.findAncestorStateOfType<_LoginViewState>();
                if (parentState != null && parentState.mounted) {
                  parentState.setState(() {
                    _isLogin = !_isLogin;
                    _loginErrorMessage = null;
                    _signupErrorMessage = null;
                    sharedPasswordController.clear();
                  });
                }
              },
              child: Text(
                'Har allerede en bruger? Log ind',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
