class LoginResponse {
  String? token;
  String? userId;

  LoginResponse({this.token, this.userId});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
        token: json['token'] as String, userId: json['userId']);
  }
}
