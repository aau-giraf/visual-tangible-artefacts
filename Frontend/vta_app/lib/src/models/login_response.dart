import 'package:vta_app/src/models/user.dart';

class LoginResponse {
  String? token;

  LoginResponse({this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(token: json['token'] as String);
  }
}
