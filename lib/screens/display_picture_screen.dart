import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // Import the share_plus package
import 'package:path_provider/path_provider.dart'; // Import the path_provider package
import 'package:social_share/social_share.dart';

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  DisplayPictureScreen(
      {required this.imagePath, required BuildContext context});

  Future<void> saveImageToGallery() async {
    final result = await Permission.storage.request();
    if (result.isGranted) {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(imageBytes);
      print('Image saved to gallery: $result');
    } else {
      print('Permission denied');
    }
  }

  Future<void> shareImageToInstagramStory() async {
    await SocialShare.shareInstagramStory(
      appId: '1110657243906107',
      imagePath: imagePath,
      backgroundTopColor: "#ffffff",
      backgroundBottomColor: "#000000",
    );

    final File imageFile = File(imagePath);
    final Uint8List imageBytes = await imageFile.readAsBytes();
    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/temp_image.jpg').create();
    await tempFile.writeAsBytes(imageBytes);

    final XFile xFile = XFile(tempFile.path);
  }

  Future<void> shareImageToInstagramFeed() async {
    final File imageFile = File(imagePath);
    final Uint8List imageBytes = await imageFile.readAsBytes();
    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/temp_image.jpg').create();
    await tempFile.writeAsBytes(imageBytes);

    final XFile xFile = XFile(tempFile.path);

    Share.shareXFiles([xFile],
        sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
        text: 'Check out my post on Instagram!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display the Picture'),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            color: Colors.black,
            child: Image.file(
              File(imagePath),
              fit: BoxFit
                  .cover, // Ensure the image fits within the bounds without distortion
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () async {
              await saveImageToGallery();
            },
            child: Icon(Icons.download, color: Colors.black),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () async {
              await shareImageToInstagramStory();
            },
            child: Icon(Icons.insert_photo, color: Colors.black),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () async {
              await shareImageToInstagramFeed();
            },
            child: Icon(Icons.share, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
