import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class ImageListScreen extends StatefulWidget {
  @override
  _ImageListScreenState createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
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
      print("Error loading images: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine all images
    List<Widget> imageWidgets = [];

    // Add title for asset images
    imageWidgets.add(
        Padding(
          padding: EdgeInsets.only(top: 15, bottom: 10, left: 15),
          child: Text(
            'Local Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
    );

    // Add asset images
    for (int i = 0; i < assetImages.length; i++) {
      imageWidgets.add(
          EnhancedImageContainer(
            image: Image.asset(assetImages[i]),
            title: 'Local Image ${i+1}',
          )
      );
    }

    // Add title for network images
    imageWidgets.add(
        Padding(
          padding: EdgeInsets.only(top: 20, bottom: 10, left: 15),
          child: Text(
            'Network Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
    );

    // Add network images
    for (int i = 0; i < networkImages.length; i++) {
      imageWidgets.add(
          EnhancedImageContainer(
            image: Image.network(networkImages[i]),
            title: 'Network Image ${i+1}',
          )
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Images'),
        centerTitle: true,
        elevation: 2,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        padding: EdgeInsets.all(10),
        children: imageWidgets,
      ),
    );
  }
}

class EnhancedImageContainer extends StatelessWidget {
  final Image image;
  final String title;

  EnhancedImageContainer({
    required this.image,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: image,
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}