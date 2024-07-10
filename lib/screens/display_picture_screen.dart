import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // Import the share_plus package
import 'package:path_provider/path_provider.dart'; // Import the path_provider package
import 'package:snapit/screens/home_screen.dart';
import 'package:social_share/social_share.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart'
    hide Image; // Avoiding conflict with image package

class DisplayPictureScreen extends StatefulWidget {
  final List<String> takenPictures;
  final String appId;

  DisplayPictureScreen({
    required this.takenPictures,
    required BuildContext context,
  }) : appId = dotenv.env['APP_ID']!;

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  late Color selectedFrameColor;
  late img.Image displayedImage;
  late String imageFilePath;

  @override
  void initState() {
    super.initState();
    selectedFrameColor = Colors.white;
    mergeImages(widget.takenPictures, selectedFrameColor);
  }

  Future<void> saveImageToGallery() async {
    final result = await Permission.storage.request();
    if (result.isGranted) {
      final File imageFile = File(imageFilePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(imageBytes);
      print('Image saved to gallery: $result');
    } else {
      print('Permission denied');
    }
  }

  Future<void> shareImageToInstagramStory() async {
    await SocialShare.shareInstagramStory(
      appId: widget.appId,
      imagePath: imageFilePath,
      backgroundTopColor: "#ffffff",
      backgroundBottomColor: "#000000",
    );
  }

  Future<void> shareImage() async {
    File imageFile = File(imageFilePath);
    final Uint8List imageBytes = imageFile.readAsBytesSync();

    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/temp_image.jpg').create();
    await tempFile.writeAsBytes(imageBytes);

    final XFile xFile = XFile(tempFile.path);

    Share.shareXFiles([xFile],
        sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
        subject: widget.appId,
        text: 'SnapIT!');
  }

  void applyFrameColor(Color color) {
    mergeImages(widget.takenPictures, color);
    setState(() {
      selectedFrameColor = color;
    });
  }

  Future<void> mergeImages(
      List<String> imagePaths, Color backgroundColor) async {
    List<img.Image> images = [];

    for (String path in imagePaths) {
      img.Image image = img.decodeImage(File(path).readAsBytesSync())!;
      images.add(image);
    }

    ByteData logoData = await rootBundle.load('assets/logo_black.png');
    img.Image logoImage = img.decodeImage(logoData.buffer.asUint8List())!;
    if (backgroundColor == Colors.black) {
      for (int y = 0; y < logoImage.height; y++) {
        for (int x = 0; x < logoImage.width; x++) {
          if (logoImage.getPixel(x, y) == img.getColor(0, 0, 0)) {
            logoImage.setPixel(x, y, img.getColor(255, 255, 255));
          }
        }
      }
    }

    int imageWidth = images[0].width;
    int imageHeight = images[0].height;

    int gap = 35;

    int width = (imageWidth * 2) + (7 * gap);
    int height = (imageHeight * 4) + (3 * gap) + logoImage.height + gap;

    img.Image mergedImage = img.Image(width, height + 360);

    img.fill(
        mergedImage,
        img.getColor(
            backgroundColor.red, backgroundColor.green, backgroundColor.blue));

    int offsetY = 60;
    for (img.Image image in images) {
      img.copyInto(mergedImage, image, dstX: gap * 2, dstY: offsetY);
      offsetY += (image.height + 2 * gap);
    }

    img.copyInto(mergedImage, logoImage,
        dstX: (mergedImage.width ~/ 2 - logoImage.width) ~/ 2,
        dstY: offsetY + gap);

    img.copyInto(mergedImage, mergedImage,
        dstX: mergedImage.width ~/ 2, dstY: 0);

    setState(() {
      displayedImage = mergedImage;
    });

    createImageFile(mergedImage);
  }

  Future<String> createImageFile(img.Image displayedImage) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/temp_image.png').create();
    await tempFile.writeAsBytes(img.encodePng(displayedImage));

    setState(() {
      imageFilePath = tempFile.path;
    });

    return tempFile.path;
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> frameColors = [
      const Color.fromARGB(255, 255, 200, 221),
      const Color.fromARGB(255, 255, 175, 204),
      const Color.fromARGB(255, 255, 173, 173),
      const Color.fromARGB(255, 255, 214, 165),
      const Color.fromARGB(255, 253, 255, 182),
      const Color.fromARGB(255, 202, 255, 191),
      const Color.fromARGB(255, 189, 224, 254),
      const Color.fromARGB(255, 162, 210, 255),
      const Color.fromARGB(255, 160, 196, 255),
      const Color.fromARGB(255, 189, 178, 255),
      const Color.fromARGB(255, 205, 180, 219),
      const Color.fromARGB(255, 192, 192, 192),
      Colors.black,
      Colors.white,
    ];

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
                child: displayedImage != null
                    ? Image.memory(
                        Uint8List.fromList(img.encodePng(displayedImage)),
                        fit: BoxFit.cover)
                    : CircularProgressIndicator(),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 16.0,
                children: frameColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      applyFrameColor(color);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedFrameColor == color
                              ? Colors.black
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
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
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
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
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: () async {
                await shareImage();
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
