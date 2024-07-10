import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snapit/screens/home_screen.dart';
import 'package:social_share/social_share.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart' hide Image;

class DisplayPictureScreen extends StatefulWidget {
  final img.Image mergedFourImage;
  final img.Image logoImage;
  final String appId;

  DisplayPictureScreen({
    required this.mergedFourImage,
    required this.logoImage,
    required BuildContext context,
  }) : appId = dotenv.env['APP_ID']!;

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  Color selectedFrameColor = Colors.white;
  late img.Image coloredImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    applyFrameColor(selectedFrameColor);
  }

  void applyFrameColor(Color color) async {
    setState(() {
      selectedFrameColor = color;
      isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 50)); // Ensure UI updates

    coloredImage =
        img.Image(widget.mergedFourImage.width, widget.mergedFourImage.height);

    img.fill(coloredImage, img.getColor(color.red, color.green, color.blue));

    img.copyInto(coloredImage, widget.mergedFourImage, dstX: 0, dstY: 0);

    img.Image logoToApply =
        color == Colors.black ? _invertLogo() : widget.logoImage;
    img.copyInto(coloredImage, logoToApply,
        dstX: (coloredImage.width ~/ 2 - logoToApply.width) ~/ 2,
        dstY: coloredImage.height - logoToApply.height - 120);

    img.copyInto(coloredImage, logoToApply,
        dstX: coloredImage.width -
            ((coloredImage.width ~/ 2 + logoToApply.width) ~/ 2),
        dstY: coloredImage.height - logoToApply.height - 120);

    setState(() {
      isLoading = false;
    });
  }

  img.Image _invertLogo() {
    img.Image invertedLogo = img.copyResize(widget.logoImage,
        width: widget.logoImage.width, height: widget.logoImage.height);
    for (int y = 0; y < invertedLogo.height; y++) {
      for (int x = 0; x < invertedLogo.width; x++) {
        if (invertedLogo.getPixel(x, y) == img.getColor(0, 0, 0)) {
          invertedLogo.setPixel(x, y, img.getColor(255, 255, 255));
        }
      }
    }
    return invertedLogo;
  }

  Future<String> createImageFile(img.Image displayedImage) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/temp_image.png').create();
    await tempFile.writeAsBytes(img.encodePng(displayedImage));

    return tempFile.path;
  }

  Future<void> saveImageToGallery() async {
    String imageFilePath = await createImageFile(coloredImage);

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
    String imageFilePath = await createImageFile(coloredImage);

    await SocialShare.shareInstagramStory(
      appId: widget.appId,
      imagePath: imageFilePath,
      backgroundTopColor: "#ffffff",
      backgroundBottomColor: "#000000",
    );
  }

  Future<void> shareImage() async {
    String imageFilePath = await createImageFile(coloredImage);

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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
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
                child: isLoading
                    ? Text('Loading...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Roboto'))
                    : Image.memory(
                        Uint8List.fromList(img.encodePng(coloredImage)),
                        fit: BoxFit.cover),
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
                              ? Colors.grey[900]!
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
              onPressed: saveImageToGallery,
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
              onPressed: shareImageToInstagramStory,
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
              onPressed: shareImage,
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
