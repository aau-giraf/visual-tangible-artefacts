import 'dart:ffi';
import 'dart:typed_data';

import 'package:vta_app/src/utilities/json/json_serializable.dart';

class Artefact implements JsonSerializable {
  String? artefactId;
  int? artefactIndex;
  String? userId;
  String? categoryId;
  String? imageUrl;
  Uint8List? image;

  Artefact(
      {this.artefactIndex,
      this.artefactId,
      this.categoryId,
      this.imageUrl,
      this.userId,
      this.image});
  factory Artefact.fromJson(Map<String, dynamic> json) {
    return Artefact(
        artefactId: json['artefactId'] as String?,
        artefactIndex: json['artefactIndex'] as int?,
        userId: json['userId'] as String?,
        categoryId: json['categoryId'] as String?,
        imageUrl: json['imagePath'] as String?,
        image: json['image'] != null
            ? Uint8List.fromList(json['image'].cast<int>())
            : null);
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'artefactId': artefactId,
      'artefactIndex': artefactIndex,
      'userId': userId,
      'categoryId': categoryId,
      'imagePath': imageUrl,
      'image': image,
    };
  }
}
