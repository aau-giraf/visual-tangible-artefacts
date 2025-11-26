import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/utilities/json/json_serializable.dart';

enum UserRole { child, caregiver, admin }

class User implements JsonSerializable {
  String id;
  String? name;
  String username;
  UserRole role;
  List<Category>? categories;

  User({
    required this.id,
    this.name,
    required this.username,
    required this.role,
    this.categories,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String?,
      username: json['username'] as String,
      role: UserRole.values[json['role'] as int],
      categories: (json['categories'] as List<dynamic>?)
          ?.map(
              (category) => Category.fromJson(category as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
}
