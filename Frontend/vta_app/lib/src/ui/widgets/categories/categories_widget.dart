import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/categories/category.dart';

class CategoriesWidget extends StatefulWidget {
  final List<Category> categories;
  final List<String> imageMatrix;
  final double widgetHeight;
  final Function(bool isMatrixVisible) isMatrixVisible;

  const CategoriesWidget(
      {super.key,
      required this.categories,
      required this.imageMatrix,
      required this.widgetHeight,
      required this.isMatrixVisible});

  @override
  State<StatefulWidget> createState() => _CategoriesWidgetState();
}

class _CategoriesWidgetState extends State<CategoriesWidget> {
  bool _isMatrixVisible = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        height: widget.widgetHeight,
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(10), right: Radius.circular(10)),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories.length,
            itemBuilder: (context, index) {
              final item = widget.categories[index];
              return TextButton(
                onPressed: () {
                  setState(() {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (BuildContext context) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: FractionallySizedBox(
                              // margin: const EdgeInsets.all(10),
                              heightFactor: 0.8,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(10),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: widget.imageMatrix.length,
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                        widget.imageMatrix[index],
                                        fit: BoxFit.cover),
                                  );
                                },
                              ),
                            ),
                          );
                        });
                    widget.isMatrixVisible(!_isMatrixVisible);
                    _isMatrixVisible = !_isMatrixVisible;
                  });
                },
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // border: Border.all(color: Colors.white, width: 10),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Text(item.id),
                        const SizedBox(width: 5),
                        if (item.imageLink != null)
                          Image.network(item.imageLink!,
                              fit: BoxFit.contain, width: 70),
                      ],
                    )),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 10),
          ),
        ));
  }
}