import 'package:vta_app/src/utilities/json/json_serializable.dart';

class SignupForm implements JsonSerializable {
  String? username;
  String? password;
  String? name;

  SignupForm({this.username, this.password, this.name});

  @override
  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password, 'name': name};
  }
}
