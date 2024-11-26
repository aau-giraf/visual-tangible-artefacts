import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vta_app/src/controllers/board_controller.dart';
import 'artefact.dart';

class TalkingMat extends StatefulWidget {
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final BoardController boardController;
  const TalkingMat({super.key,
    this.width,
    this.height,
    this.backgroundColor,
    required this.boardController
  });

  @override
  createState() => TalkingMatState();
}

class TalkingMatState extends State<TalkingMat> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-2.5, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardController = widget.boardController;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: widget.height ?? constraints.maxHeight,
          width: widget.width ?? constraints.maxWidth,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...boardController.artefacts.map((artefact) {
                boardController.loadArtefactSize(artefact); // Ensure the artifact size is captured
                return Positioned(
                  left: artefact.position?.dx,
                  top: artefact.position?.dy,
                  child: Draggable<BoardArtefact>(
                    data: artefact,
                    feedback: Transform.scale(
                      scale: 1.2,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 5,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Opacity(
                          opacity: 0.5,
                          child: artefact.content,
                        ),
                      ),
                    ),
                    childWhenDragging: Container(),
                    child:
                        Container(key: artefact.key, child: artefact.content),
                    onDragEnd: (details) {
                      if (boardController.isInsideMat(details.offset, context)) {
                        boardController.updateArtefactPosition(artefact, details.offset, context);
                      }
                    },
                  ),
                );
              }),
              Align(
                alignment: Alignment.lerp(
                        Alignment.bottomCenter, Alignment.center, 0.1) ??
                    Alignment.bottomCenter,
                child: Stack(alignment: Alignment.center, children: [
                  SlideTransition(
                      position: _offsetAnimation,
                      child:boardController.showDeleteHover
                          ? buildTrashCan(
                              height: 30,
                              width: 30,
                              color: const Color.fromARGB(255, 235, 32, 18))
                          : null),
                  GestureDetector(
                    onTap: () {
                      boardController.removeArtefactsPopUp(context);
                    },
                    child: DragTarget<BoardArtefact>(
                      builder: (context, data, rejectedData) {
                        return buildTrashCan(
                          height: boardController.isDraggingOverTrashCan ? 120 : 50,
                          width: boardController.isDraggingOverTrashCan ? 120 : 50,
                        );
                      },
                      onAcceptWithDetails: (details) {
                        var artefactKey = details.data.key;
                        boardController.removeArtefact(artefactKey);
                        _animationController.reverse();
                        // Listen for the animation status
                        _animationController.addStatusListener((status) {
                          if (status == AnimationStatus.dismissed) {
                            // Wait until animation is fully reversed
                            setState(() {
                              boardController.setDeleteHover(false);
                            });
                          }
                        });
                      },
                      onWillAcceptWithDetails: (details) {
                        setState(() {
                          boardController.setDeleteHover(true);
                          boardController.setOverTrashCan(true);
                        });
                        _animationController.forward();
                        return true;
                      },
                      onLeave: (details) {
                        _animationController.reverse();
                        boardController.setOverTrashCan(false);
                        // Listen for the animation status
                        _animationController.addStatusListener((status) {
                          if (status == AnimationStatus.dismissed) {
                            // Wait until animation is fully reversed
                            setState(() {
                              boardController.setDeleteHover(false);
                            });
                          }
                        });
                      },
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTrashCan(
      {
        double width = 50,
      double height = 50,
      Color color = const Color(0xFFF0F2D9)}) {
    return Stack(children: [
      Container(
        width: width,
        height: width,
        decoration: ShapeDecoration(
          color: color,
          shape: const OvalBorder(),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
              spreadRadius: 0,
            )
          ],
        ),
        child: Center(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/icons/trash_bin.png'),
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
