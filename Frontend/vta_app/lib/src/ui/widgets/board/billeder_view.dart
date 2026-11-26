import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';

const Color _viewBackground = Color(0xFFFBF7F4);
const Color _underlineColor = Color(0xFFFEC377); // same as the panel title
const Color _plusColor = Color(0xFFF59E3D);

class BillederView extends StatefulWidget {
  const BillederView({
    super.key,
    required this.isOpen,
    required this.artefactController,
    required this.onArtifactAdded,
    required this.onClose,
    this.borderRadius = BorderRadius.zero,
  });

  final bool isOpen;
  final ArtefactController artefactController;
  final void Function(BoardArtefact) onArtifactAdded;
  final VoidCallback onClose; // closes the whole hub
  final BorderRadius borderRadius;

  @override
  State<BillederView> createState() => _BillederViewState();
}

class _BillederViewState extends State<BillederView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _foldersScroll = ScrollController();
  final ScrollController _picturesScroll = ScrollController();
  Category? _openCategory;
  String _query = '';

  @override
  void didUpdateWidget(BillederView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always start on the folder list when the view is opened
    if (!oldWidget.isOpen && widget.isOpen) {
      _openCategory = null;
      _query = '';
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _foldersScroll.dispose();
    _picturesScroll.dispose();
    super.dispose();
  }

  Map<String, String> _headers() => {
        'Authorization': 'Bearer ${GetIt.instance.get<Token>().value}',
      };

  // Look the open category up again so new pictures show up
  Category? _currentCategory(List<Category> categories) {
    final open = _openCategory;
    if (open == null) return null;
    for (final category in categories) {
      if (category.categoryId == open.categoryId) return category;
    }
    return open;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 600;

    return Material(
      color: _viewBackground,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: ListenableBuilder(
        listenable: widget.artefactController,
        builder: (context, _) {
          final categories = widget.artefactController.categories ?? [];
          final open = _currentCategory(categories);

          return Padding(
            padding: EdgeInsets.fromLTRB(
                wide ? 24 : 12, wide ? 16 : 10, wide ? 16 : 8, 12),
            child: Column(
              children: [
                open == null ? _buildFolderHeader() : _buildPictureHeader(open),
                const SizedBox(height: 12),
                Expanded(
                  child: open == null
                      ? _buildFolderGrid(categories)
                      : _buildPictureGrid(open),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Folder level: [+] [search] [X] ---

  Widget _buildFolderHeader() {
    final searchBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    );

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Tooltip(
            message: 'Opret ny kategori',
            child: Material(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => widget.artefactController.newCategory(context),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Søg',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: searchBorder,
                enabledBorder: searchBorder,
                focusedBorder: searchBorder,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Luk',
            iconSize: 28,
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildFolderGrid(List<Category> categories) {
    final query = _query.trim().toLowerCase();
    final visible = categories
        .where((c) => (c.name ?? '').toLowerCase().contains(query))
        .toList();

    if (visible.isEmpty) {
      return Center(
        child: Text(
          categories.isEmpty
              ? 'Ingen kategorier endnu. Tryk på + for at oprette en.'
              : 'Ingen kategorier fundet',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 130).floor().clamp(2, 5);

        return Scrollbar(
          controller: _foldersScroll,
          thumbVisibility: true,
          child: GridView.builder(
            controller: _foldersScroll,
            padding: const EdgeInsets.only(right: 12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final category = visible[index];
              return _FolderTile(
                name: category.name ?? '',
                onTap: () {
                  widget.artefactController.trackCategoryUsage(
                      category.categoryId!,
                      context: context);
                  setState(() => _openCategory = category);
                },
              );
            },
          ),
        );
      },
    );
  }

  // --- Picture level: centered title + back button ---

  Widget _buildPictureHeader(Category open) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _underlineColor, width: 1),
                ),
              ),
              child: Text(
                open.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, color: Colors.black87),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Tooltip(
              message: 'Tilbage',
              child: Material(
                color: const Color(0xFFBDBDBD),
                borderRadius: BorderRadius.circular(6),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _openCategory = null),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(Icons.keyboard_return,
                        size: 20, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPictureGrid(Category category) {
    final artefacts = category.artefacts ?? [];
    final headers = _headers();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 130).floor().clamp(2, 5);

        return Scrollbar(
          controller: _picturesScroll,
          thumbVisibility: true,
          child: GridView.builder(
            controller: _picturesScroll,
            padding: const EdgeInsets.only(right: 12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.95,
            ),
            itemCount: artefacts.length + 1, // +1 for the add tile
            itemBuilder: (context, index) {
              if (index == 0) return _buildAddPictureTile(category);

              final artefact = artefacts[index - 1];
              return _PictureTile(
                imageUrl: artefact.imageUrl,
                name: artefact.name,
                headers: headers,
                onTap: () {
                  widget.onArtifactAdded(
                    BoardArtefact.fromArtefact(artefact, headers: headers),
                  );
                  widget.onClose();
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAddPictureTile(Category category) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.artefactController
            .newArtifact(context, category.categoryId!),
        child: const Center(
          child: Icon(Icons.add_circle_outline, color: _plusColor, size: 36),
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: const Icon(
                Icons.folder_outlined,
                size: 100,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _PictureTile extends StatelessWidget {
  const _PictureTile({
    required this.imageUrl,
    required this.name,
    required this.headers,
    required this.onTap,
  });

  final String? imageUrl;
  final String? name;
  final Map<String, String> headers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Text(
                name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: hasImage
                    ? Image.network(
                        imageUrl!,
                        headers: headers,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.black26),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}