import 'package:vta_app/src/models/user.dart';

class SignupResponse {
  User? user;
  String? token;

  SignupResponse({this.user, this.token});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
        user: User.fromJson(json['user']), token: json['token'] as String?);
  }
}
