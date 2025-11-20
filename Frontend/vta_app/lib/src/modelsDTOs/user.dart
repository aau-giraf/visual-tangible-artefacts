import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/utilities/json/json_serializable.dart';

class User implements JsonSerializable {
  String id;
  String? name;
  String guardianKey;
  String username;
  bool nameVisible;
  int fieldCount;
  List<Category>? categories;

  User({
    required this.id,
    this.name,
    required this.guardianKey,
    required this.username,
    required this.nameVisible,
    required this.fieldCount,
    this.categories,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String?,
      guardianKey: json['guardianKey'] as String,
      username: json['username'] as String,
      nameVisible: json['nameVisible'] as bool? ?? false,
      fieldCount: json['fieldCount'] as int? ?? 4,
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
