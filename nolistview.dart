import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class ImageGridGallery extends StatefulWidget {
  const ImageGridGallery({Key? key}) : super(key: key);

  @override
  _ImageGridGalleryState createState() => _ImageGridGalleryState();
}

class _ImageGridGalleryState extends State<ImageGridGallery> {
  List<String> assetImages = [];
  List<String> networkImages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> loadImages() async {
    try {
      final String response = await rootBundle.loadString('assets/images.json');
      final data = json.decode(response);

      setState(() {
        assetImages = List<String>.from(data['assetImages']);
        networkImages = List<String>.from(data['networkImages']);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error loading images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine asset and network images
    final allImages = [
      ...assetImages.map((path) => ImageItem(path, true)),
      ...networkImages.map((url) => ImageItem(url, false)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Image Gallery',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'All Images',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  return GridImageCard(
                    imagePath: allImages[index].path,
                    isAsset: allImages[index].isAsset,
                    index: index,
                    assetImagesCount: assetImages.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageItem {
  final String path;
  final bool isAsset;

  ImageItem(this.path, this.isAsset);
}

class GridImageCard extends StatelessWidget {
  final String imagePath;
  final bool isAsset;
  final int index;
  final int assetImagesCount;

  const GridImageCard({
    Key? key,
    required this.imagePath,
    required this.isAsset,
    required this.index,
    required this.assetImagesCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            isAsset
                ? Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.red, size: 40),
                  ),
                );
              },
            )
                : Image.network(
              imagePath,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.red, size: 40),
                  ),
                );
              },
            ),
            // Image overlay with gradient and label
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAsset ? 'Local' : 'Network',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      isAsset ? '${index + 1}' : '${index + 1 - assetImagesCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Interactive layer
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showImageDetails(context, imagePath, isAsset);
                },
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDetails(BuildContext context, String path, bool isAsset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 3,
              child: isAsset
                  ? Image.asset(path)
                  : Image.network(
                path,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}