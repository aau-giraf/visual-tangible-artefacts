import 'package:vta_app/src/utilities/json/json_serializable.dart';

class Artefact implements JsonSerializable {
  String? artefactId;
  int? artefactIndex;
  String? userId;
  String? categoryId;
  String? imageUrl;

  Artefact(
      {this.artefactIndex,
      this.artefactId,
      this.categoryId,
      this.imageUrl,
      this.userId});
  factory Artefact.fromJson(Map<String, dynamic> json) {
    return Artefact(
        artefactId: json['artefactId'] as String,
        artefactIndex: json['artefactIndex'] as int,
        userId: json['userId'] as String,
        categoryId: json['categoryId'],
        imageUrl: json['imageUrl']);
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'artefactId': artefactId,
      'artefactIndex': artefactIndex,
      'userId': userId,
      'categoryId': categoryId,
      'imageUrl': imageUrl
    };
  }
}
