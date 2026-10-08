import 'package:vta_app/src/modelsDTOs/user.dart';

/// Represents a response to a signup request, containing a user object and an optional token.
class SignupResponse {
  User? user;
  String? token;

  SignupResponse({this.user, this.token});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
        user: User.fromJson(json['user']), token: json['token'] as String?);
  }
}
