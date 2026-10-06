import 'package:vta_app/src/utilities/json/json_serializable.dart';

/// List of available user roles in the application.
enum UserRole { child, caregiver, admin }

/// Represents a signup form with username, password, name, and role fields.
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
