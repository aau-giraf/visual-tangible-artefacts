import 'package:vta_app/src/utilities/json/json_serializable.dart';

enum UserRole { child, caregiver, admin }

class SignupForm implements JsonSerializable {
  String username;
  String password;
  String name;
  UserRole role;

  SignupForm(
      {required this.username,
      required this.password,
      required this.name,
      this.role = UserRole.child});

  @override
  Map<String, dynamic> toJson() {
    return {
      'Username': username,
      'Password': password,
      'Name': name,
      'Role': role.index
    };
  }
}
