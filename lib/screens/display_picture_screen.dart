import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // Import the share_plus package
import 'package:path_provider/path_provider.dart'; // Import the path_provider package
import 'package:snapit/screens/home_screen.dart';
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
        subject: '1110657243906107',
        text: 'Check out my post on Instagram!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the default back button
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => HomeScreen(camerasAvailable: true)),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 40),
            Flexible(
              flex: 3,
              child: Center(
                child: Image.file(File(imagePath), fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerFloat, // Center the floating action button row
      floatingActionButton: Row(
        mainAxisSize:
            MainAxisSize.min, // Shrink the row to the size of its children
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.white, width: 3), // Set border color and width
              borderRadius: BorderRadius.circular(
                  20), // Match the border radius to the FloatingActionButton
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: () async {
                await saveImageToGallery();
              },
              child: Icon(
                Icons.download,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.white, width: 3), // Set border color and width
              borderRadius: BorderRadius.circular(
                  20), // Match the border radius to the FloatingActionButton
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: () async {
                await shareImageToInstagramStory();
              },
              child: Image.asset(
                'assets/instagram_icon_bw.png',
                width: 28,
                height: 28,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.white, width: 3), // Set border color and width
              borderRadius: BorderRadius.circular(
                  20), // Match the border radius to the FloatingActionButton
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: () async {
                await shareImageToInstagramFeed();
              },
              child: Icon(
                Icons.share,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
