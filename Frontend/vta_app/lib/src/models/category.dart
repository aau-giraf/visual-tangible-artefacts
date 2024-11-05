import 'dart:typed_data';
import 'package:vta_app/src/models/artefact.dart';
import 'package:vta_app/src/utilities/json/json_serializable.dart';

class Category implements JsonSerializable {
  String? userId;
  String? categoryId;
  int? categoryIndex;
  String? name;
  List<Artefact>? artefacts;
  String? imageUrl;
  Uint8List? image;

  Category(
      {this.categoryId,
      this.categoryIndex,
      this.name,
      this.artefacts,
      this.userId,
      this.imageUrl,
      this.image});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
        userId: json['userId'] != null ? json['userId'] as String : null,
        categoryId: json['categoryId'] as String?,
        categoryIndex: json['categoryIndex'] as int?,
        name: json['name'] as String?,
        artefacts: (json['artefacts'] as List<dynamic>?)
            ?.map((artefact) =>
                Artefact.fromJson(artefact as Map<String, dynamic>))
            .toList(),
        imageUrl: json['imageUrl'] as String?,
        image: json['image'] != null
            ? Uint8List.fromList(json['image'].cast<int>())
            : null);
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'categoryId': categoryId,
      'categoryIndex': categoryIndex,
      'name': name,
      'artefacts': artefacts?.map((artefact) => artefact.toJson()).toList(),
      'imageUrl': imageUrl,
      'image': image?.toList(),
    };
  }
}
