import 'package:flutter/material.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';

class BoardArtefact {
  final Widget content;
  Offset? position;
  final GlobalKey key;
  Size? renderedSize;
  Artefact? baseArtefact;

  BoardArtefact({
    required this.content,
    this.position,
    this.baseArtefact,
  }) : key = GlobalKey();

  factory BoardArtefact.fromArtefact(Artefact artefact,
      {Map<String, String>? headers}) {
    return BoardArtefact(
        content: SizedBox(
          width: 200,
          height: 200,
          child: FadeInImage(
            imageErrorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/images/flutter_logo.png');
            },
            image: NetworkImage(artefact.imageUrl ?? "", headers: headers),
            placeholder: AssetImage('assets/images/flutter_logo.png'),
          ),
        ),
        baseArtefact: artefact);
  }
}
