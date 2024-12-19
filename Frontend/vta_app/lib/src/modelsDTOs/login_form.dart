import 'package:vta_app/src/utilities/json/json_serializable.dart';

class LoginForm implements JsonSerializable {
  String? username;
  String? password;
  LoginForm({this.username, this.password});
  @override
  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}
