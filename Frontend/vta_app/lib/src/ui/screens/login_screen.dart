import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/models/login_form.dart';
import 'package:vta_app/src/models/login_response.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'dart:convert';
import 'artifact_board_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiProvider apiProvider =
      ApiProvider(baseUrl: 'https://localhost:7180/api');

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        print('Form validated');
        var loginForm = LoginForm(
            username: _usernameController.text,
            password: _passwordController.text);

        final response = await apiProvider.postAsJson('/Users/Login',
            body: loginForm.toJson());

        print('HTTP request sent');
        print('Response status: ${response?.statusCode}');
        print('Response body: ${response?.body}');

        if (response != null && response.statusCode == 200) {
          var loginResponse =
              LoginResponse.fromJson(json.decode(response.body));
          String token = loginResponse.token ?? "";
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);

          // Navigate to user page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => ArtifactBoardScreen()),
          );
        } else {
          // Handle login failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed')),
          );
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } else {
      print('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
