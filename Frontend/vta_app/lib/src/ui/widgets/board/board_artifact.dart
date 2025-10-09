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
      {Map<String, String>? headers, BuildContext? context}) {
    // Calculate responsive size based on screen width
    double screenWidth = context != null ? MediaQuery.of(context).size.width : 400;
    double artifactSize = screenWidth > 600 ? 200 : screenWidth * 0.3;
    
    return BoardArtefact(
        content: SizedBox(
          width: artifactSize,
          height: artifactSize,
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
