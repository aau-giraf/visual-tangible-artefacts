  // Removed duplicate displayName getter
import 'dart:typed_data';

import 'package:vta_app/src/utilities/json/json_serializable.dart';

class Artefact implements JsonSerializable {
  String? artefactId;
  int? artefactIndex;
  String? userId;
  String? categoryId;
  String? imageUrl;
  String? soundUrl;
  Uint8List? image;
  Uint8List? sound;
  String? name;
  bool? nameShown;
  
  Artefact({
    this.artefactIndex,
    this.artefactId,
    this.categoryId,
    this.imageUrl,
    this.soundUrl,
    this.userId,
    this.image,
    this.sound,
    this.name,
    this.nameShown,
  });

    String get displayName => artefactId ?? 'Artefact #${artefactIndex ?? ''}';

  factory Artefact.fromJson(Map<String, dynamic> json) {
    return Artefact(
      artefactId: json['artefactId'] as String?,
      artefactIndex: json['artefactIndex'] as int?,
      userId: json['userId'] as String?,
      categoryId: json['categoryId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      soundUrl: json['soundUrl'] as String?,
      image: json['image'] != null
          ? Uint8List.fromList(json['image'].cast<int>())
          : null,
      sound: json['sound'] != null
          ? Uint8List.fromList(json['sound'].cast<int>())
          : null,
      name: json['name'] as String?,
      nameShown: json['nameShown'] as bool?,
    );
    // handle sound bytes if provided
  // Note: some endpoints may return soundUrl instead of raw bytes; this keeps raw bytes support
  // and preserves backwards compatibility.
  // (No direct assignment from JSON for sound unless the endpoint includes the bytes.)

  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'artefactId': artefactId,
      'artefactIndex': artefactIndex,
      'userId': userId,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'soundUrl': soundUrl,
      'image': image,
      'sound': sound,
      'name': name,
      'nameShown': nameShown,
    };
  }
}
