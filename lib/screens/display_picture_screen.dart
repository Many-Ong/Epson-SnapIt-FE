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
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DisplayPictureScreen extends StatefulWidget {
  final img.Image mergedFourImage;
  final String appId;

  DisplayPictureScreen({
    required this.mergedFourImage,
    required BuildContext context,
  }) : appId = dotenv.env['APP_ID']!;

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  Color selectedFrameColor = Colors.white;
  late Uint8List originalImageBytes; // Store the original image bytes
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the original image bytes
    originalImageBytes =
        Uint8List.fromList(img.encodePng(widget.mergedFourImage));
  }

  Future<String> createImageFile(Uint8List imageBytes) async {
    // Create the framed image with the selected frame color
    final framedImage =
        applyFrameColor(widget.mergedFourImage, selectedFrameColor);

    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/temp_image.png').create();
    await tempFile.writeAsBytes(img.encodePng(framedImage));
    return tempFile.path;
  }

  // Function to apply frame color to the image
  img.Image applyFrameColor(img.Image baseImage, Color frameColor) {
    // Create a new image with padding for the frame
    final int frameWidth = 20; // Set frame width
    final img.Image framedImage = img.Image(
      baseImage.width + 2 * frameWidth,
      baseImage.height + 2 * frameWidth,
    );

    // Fill the frame area with the selected color
    img.fill(framedImage,
        img.getColor(frameColor.red, frameColor.green, frameColor.blue));

    // Copy the original image onto the framed image
    img.copyInto(framedImage, baseImage, dstX: frameWidth, dstY: frameWidth);

    return framedImage;
  }

  Future<void> saveImageToGallery() async {
    String imageFilePath = await createImageFile(originalImageBytes);

    final result = await Permission.storage.request();
    if (result.isGranted) {
      final File imageFile = File(imageFilePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(imageBytes);
      print('Image saved to gallery: $result');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image Saved', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      print('Permission denied');
    }
  }

  Future<void> checkAndShareImageToInstagramStory() async {
    const instagramUrl = 'instagram://app';
    if (await canLaunchUrlString(instagramUrl)) {
      await shareImageToInstagramStory();
    } else {
      print('Instagram not installed');
      showInstallInstagramDialog();
    }
  }

  void showInstallInstagramDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Instagram Not Installed'),
          content: Text('Install Instagram to share your story?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Install'),
              onPressed: () {
                launch('https://apps.apple.com/us/app/instagram/id389801252');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> shareImageToInstagramStory() async {
    String imageFilePath = await createImageFile(originalImageBytes);

    await SocialShare.shareInstagramStory(
      appId: widget.appId,
      imagePath: imageFilePath,
      backgroundTopColor: "#ffffff",
      backgroundBottomColor: "#000000",
    );
  }

  Future<void> shareImage() async {
    String imageFilePath = await createImageFile(originalImageBytes);

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

  Future<bool> _onWillPop() async {
    return (await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Do you want to exit?'),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                textStyle: TextStyle(color: Colors.blue),
                child: Text('No'),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(true),
                textStyle: TextStyle(color: Colors.blue),
                child: Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> frameColors = [
      const Color.fromARGB(255, 171, 39, 52),
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
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () async {
              bool exit = await _onWillPop();
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
                    : Container(
                        padding: EdgeInsets.all(2), // Padding for the frame
                        color: selectedFrameColor, // Frame color
                        child: Image.memory(
                          originalImageBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
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
              onPressed: checkAndShareImageToInstagramStory,
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
