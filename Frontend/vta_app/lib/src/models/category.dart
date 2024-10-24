import 'package:vta_app/src/models/artefact.dart';
import 'package:vta_app/src/utilities/json/json_serializable.dart';

class Category implements JsonSerializable {
  String? categoryId;
  int? categoryIndex;
  String? name;
  List<Artefact>? artifacts;

  Category({this.categoryId, this.categoryIndex, this.name, this.artifacts});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
        categoryId: json['categoryId'] as String,
        categoryIndex: json['categoryIndex'] as int,
        name: json['name'] as String,
        artifacts: (json['artefacts'] as List<dynamic>?)
            ?.map((artifact) =>
                Artefact.fromJson(artifact as Map<String, dynamic>))
            .toList());
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
