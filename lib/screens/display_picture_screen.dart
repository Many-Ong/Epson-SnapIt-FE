import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:snapit/utils/share_download.dart';

class DisplayPictureScreen extends StatefulWidget {
  final img.Image mergedFourImage;
  final bool isSpecialFrame;

  DisplayPictureScreen({
    super.key,
    required this.mergedFourImage,
    required this.isSpecialFrame,
    required BuildContext context,
  });

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  Color selectedFrameColor = Colors.white;
  img.Image frame = img.Image(0, 0);
  String imageFilePath = '';
  bool isProcessing = false;
  late String appId;

  @override
  void initState() {
    super.initState();
    // Initialize the original image bytes
    appId = dotenv.env['APP_ID'] ?? '';

    loadFrameImage();
    createImageFile();
  }

  Future<void> loadFrameImage() async {
    ByteData frameData = await rootBundle.load('assets/frame_special_1.png');
    frame = img.decodeImage(frameData.buffer.asUint8List())!;
  }

  Future<void> createImageFile() async {
    setState(() {
      isProcessing = true;
    });
    // Create the framed image with the selected frame color
    Uint8List imageBytes =
        await Uint8List.fromList(img.encodePng(widget.mergedFourImage));

    if (widget.isSpecialFrame) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = await File('${tempDir.path}/temp_image.png').create();
      await tempFile.writeAsBytes(img.encodePng(widget.mergedFourImage));
      imageFilePath = tempFile.path;
    }

    final framedImage =
        applyFrameColor(widget.mergedFourImage, selectedFrameColor);

    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/temp_image.png').create();
    await tempFile.writeAsBytes(img.encodePng(framedImage));
    
    imageFilePath = tempFile.path;

    setState(() {
      isProcessing = false;
    });
  }

  // Function to apply frame color to the image
  img.Image applyFrameColor(img.Image baseImage, Color frameColor) {
    // Create a new image with padding for the frame
    final img.Image framedImage = img.Image(
      baseImage.width,
      baseImage.height,
    );

    // Fill the frame area with the selected color
    img.fill(framedImage,
        img.getColor(frameColor.red, frameColor.green, frameColor.blue));

    img.copyInto(framedImage, baseImage, dstX: 0, dstY: 0);

    return framedImage;
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> frameColors = [
      const Color.fromARGB(255, 186, 12, 47),
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
      Colors.white,
    ];

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () async {
              bool exit = await onWillPop(context);
              if (exit) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => HomeScreen(
                            camerasAvailable: true,
                          )),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40),
            Flexible(
              flex: 3,
              child: Center(
                child: Container(
                        padding:
                            const EdgeInsets.all(2), // Padding for the frame
                        color: widget.isSpecialFrame
                            ? Colors.transparent
                            : selectedFrameColor,
                        child: isProcessing
                            ? CircularProgressIndicator()
                            : Image.file(
                          File(imageFilePath),
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            if (!widget.isSpecialFrame)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 16.0,
                  children: frameColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFrameColor = color;
                        });
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
            const SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: isProcessing ? [const SizedBox(height: 20)] : [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: () => saveImageToGallery(context, imageFilePath),
              child: const Icon(
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
              onPressed: () => checkAndShareImageToInstagramStory(imageFilePath, appId, context),
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
              onPressed: () => shareImage(imageFilePath, appId),
              child: const Icon(
                Icons.share,
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
                await saveImageToFirebaseStorage(context, imageFilePath); // 비동기 함수를 호출
              },
              child: const Icon(
                Icons.qr_code,
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
