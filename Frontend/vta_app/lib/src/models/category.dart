import 'package:vta_app/src/models/artefact.dart';
import 'package:vta_app/src/utilities/json/json_serializable.dart';

class Category implements JsonSerializable {
  String? categoryId;
  int? categoryIndex;
  String? name;
  List<Artefact>? artefacts;

  Category({this.categoryId, this.categoryIndex, this.name, this.artefacts});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
        categoryId: json['categoryId'] as String,
        categoryIndex: json['categoryIndex'] as int,
        name: json['name'] as String,
        artefacts: (json['artefacts'] as List<dynamic>?)
            ?.map((artefact) =>
                Artefact.fromJson(artefact as Map<String, dynamic>))
            .toList());
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'categoryId': categoryId,
      'categoryIndex': categoryIndex,
      'name': name,
      'artefacts': artefacts?.map((artefact) => artefact.toJson()).toList()
    };
  }
}
