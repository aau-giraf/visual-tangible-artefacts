import 'package:vta_app/src/utilities/json/json_serializable.dart';

class SignupForm implements JsonSerializable {
  String username;
  String password;
  String name;
  String guardianKey;

  SignupForm(
      {required this.username,
      required this.password,
      required this.name,
      required this.guardianKey});

  @override
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'guardianKey': guardianKey
    };
  }
}
