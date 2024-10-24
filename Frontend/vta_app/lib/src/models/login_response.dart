import 'package:vta_app/src/models/user.dart';

class LoginResponse {
  User? user;
  String? token;

  LoginResponse({this.user, this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
        user: User.fromJson(json['user']), token: json['token'] as String);
  }
}
