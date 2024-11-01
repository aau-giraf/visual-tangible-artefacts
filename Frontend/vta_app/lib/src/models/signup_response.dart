import 'package:vta_app/src/models/user.dart';

class SignupResponse {
  String? token;

  SignupResponse({this.token});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(token: json['token'] as String);
  }
}
