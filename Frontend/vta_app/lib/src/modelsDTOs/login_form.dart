import 'package:vta_app/src/utilities/json/json_serializable.dart';

/// Represents a login form with username and password fields.
class LoginForm implements JsonSerializable {
  String? username;
  String? password;
  LoginForm({this.username, this.password});
  @override
  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}
