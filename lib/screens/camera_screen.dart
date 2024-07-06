import 'dart:io';
import 'package:flutter/material.dart'
    hide Image; // Avoiding conflict with image package
import 'package:flutter/material.dart' as flutter;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:snapit/screens/display_picture_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final Color frameColor;
  final List<String> overlayImages;

  const CameraScreen({
    super.key,
    required this.camera,
    required this.frameColor,
    required this.overlayImages,
  });

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<CameraDescription> cameras = [];
  int pictureCount = 0;
  List<String> takePictures = [];
  int overlayIndex = 0; // New variable to keep track of the overlay image index

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    CameraDescription frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    // Ensure that the camera is initialized
    _initializeControllerFuture = _controller.initialize().then((_) async {
      if (!mounted) return;

      await _controller.setExposureMode(ExposureMode.auto);
      await _controller.setFlashMode(FlashMode.off);
      setState(() {});
    }).catchError((error) {
      print('Error initializing camera: $error');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Method to change the overlay image
  void changeOverlayImage() {
    setState(() {
      overlayIndex = (overlayIndex + 1) % widget.overlayImages.length;
    });
  }

  Future<Widget> _buildOverlayImage() async {
    String overlayPath = widget.overlayImages[overlayIndex];
    img.Image overlayImage;

    if (overlayPath.startsWith('http')) {
      final response = await http.get(Uri.parse(overlayPath));
      Uint8List bytes = response.bodyBytes;
      overlayImage = img.decodeImage(bytes)!;
    } else {
      overlayImage = img.decodeImage(File(overlayPath).readAsBytesSync())!;
    }

    Size previewSize = _controller.value.previewSize!;
    double overlayWidth = previewSize.height;
    double overlayHeight =
        (overlayWidth * overlayImage.height / overlayImage.width)
            .roundToDouble();

    return flutter.Image.memory(
      Uint8List.fromList(img.encodePng(img.copyResize(overlayImage,
          width: overlayWidth.round(), height: overlayHeight.round()))),
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: <Widget>[
                Center(
                  child: AspectRatio(
                    // aspectRatio: 4 / 3, // Adjust the aspect ratio as needed
                    aspectRatio: 3 / 4, // Adjust the aspect ratio as needed
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit
                              .cover, // Use BoxFit.cover to match cropping behavior
                          child: Container(
                            width: _controller.value.previewSize!.height,
                            height: _controller.value.previewSize!.width,
                            child: CameraPreview(
                                _controller), // This is your camera preview
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                FutureBuilder<Widget>(
                  future: _buildOverlayImage(),
                  builder: (context, overlaySnapshot) {
                    if (overlaySnapshot.connectionState ==
                        ConnectionState.done) {
                      return Center(
                        child: AspectRatio(
                          // aspectRatio: 4 / 3,
                          aspectRatio: 3 / 4,
                          child: overlaySnapshot.data,
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () async {
              try {
                await _initializeControllerFuture; // Ensure the future is complete before proceeding
                if (pictureCount < 4) {
                  final XFile image = await _controller.takePicture();
                  String overlayImagePath = await mergeImage(
                      image, widget.overlayImages[overlayIndex]);
                  takePictures.add(overlayImagePath);
                  changeOverlayImage();
                  pictureCount++;

                  if (pictureCount == 4) {
                    String mergedImagePath =
                        await mergeFourImages(takePictures, widget.frameColor);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DisplayPictureScreen(
                            imagePath: mergedImagePath, context: context),
                      ),
                    );
                    pictureCount = 0;
                    takePictures.clear();
                  }
                }
              } catch (e) {
                print(e);
              }
            },
            child: const Icon(Icons.camera_alt, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Future<String> mergeImage(XFile picture, String overlayPath) async {
    File file = File(picture.path);

    if (!file.existsSync()) {
      print('File does not exist');
      return '';
    }

    img.Image baseImage = img.decodeImage(file.readAsBytesSync())!;
    img.Image flippedImage = img.flipHorizontal(baseImage);

    // Determine crop size for 4:3 ratio
    int targetWidth, targetHeight;
    if (baseImage.width / baseImage.height > 4 / 3) {
      // Width is too wide for the height to fit a 4:3 ratio
      targetHeight = baseImage.height;
      targetWidth = (baseImage.height * 4) ~/ 3;
    } else {
      // Height is too high for the width to fit a 4:3 ratio
      targetWidth = baseImage.width;
      targetHeight = (baseImage.width * 3) ~/ 4;
    }

    // Crop the image around the center
    int startX = (baseImage.width - targetWidth) ~/ 2;
    int startY = (baseImage.height - targetHeight) ~/ 2;
    img.Image croppedImage =
        img.copyCrop(flippedImage, startX, startY, targetWidth, targetHeight);

    img.Image overlayImage;
    if (overlayPath.startsWith('http')) {
      final response = await http.get(Uri.parse(overlayPath));
      Uint8List bytes = response.bodyBytes;
      overlayImage = img.decodeImage(bytes)!;
    } else {
      overlayImage = img.decodeImage(File(overlayPath).readAsBytesSync())!;
    }

    // img.Image resizedOverlayImage = img.copyResize(
    //   overlayImage,
    //   width: croppedImage.width,
    //   height: (croppedImage.width * overlayImage.height / overlayImage.width)
    //       .round(),
    // );
    img.Image resizedOverlayImage = img.copyResize(
      overlayImage,
      width: flippedImage.width,
      height: (flippedImage.width * overlayImage.height / overlayImage.width)
          .round(),
    );

    // int offsetX = (croppedImage.width - resizedOverlayImage.width) ~/ 2;
    // int offsetY = (croppedImage.height - resizedOverlayImage.height) ~/ 2;
    // img.copyInto(croppedImage, resizedOverlayImage,
    //     dstX: offsetX, dstY: offsetY);
    int offsetX = (flippedImage.width - resizedOverlayImage.width) ~/ 2;
    int offsetY = (flippedImage.height - resizedOverlayImage.height) ~/ 2;
    img.copyInto(flippedImage, resizedOverlayImage,
        dstX: offsetX, dstY: offsetY);

    String newPath = '${file.parent.path}/merged_${DateTime.now()}.png';
    // File newImageFile = File(newPath)
    //   ..writeAsBytesSync(img.encodePng(croppedImage));
    File newImageFile = File(newPath)
      ..writeAsBytesSync(img.encodePng(flippedImage));
    print('New image saved at: $newPath');
    return newImageFile.path;
  }

  Future<String> mergeFourImages(
      List<String> imagePaths, Color backgroundColor) async {
    List<img.Image> images = [];

    for (String path in imagePaths) {
      img.Image image = img.decodeImage(File(path).readAsBytesSync())!;
      images.add(image);
    }

    // logo 이미지 코드
    ByteData logoData = await rootBundle.load('assets/logo.png');
    img.Image logoImage = img.decodeImage(logoData.buffer.asUint8List())!;
    // 배경이 흰색인 경우 검정색으로 변환
    if (backgroundColor == Colors.white) {
      for (int y = 0; y < logoImage.height; y++) {
        for (int x = 0; x < logoImage.width; x++) {
          if (logoImage.getPixel(x, y) == img.getColor(255, 255, 255)) {
            logoImage.setPixel(x, y, img.getColor(0, 0, 0));
          }
        }
      }
    }

    int imageWidth = images[0].width;
    int imageHeight = images[0].height;
    int gap = 20; // Define the gap between images
    int width = (imageWidth * 2) +
        (3 * gap); // Two images side by side with padding and gaps
    int height = (imageHeight * 2) +
        (3 * gap) +
        logoImage.height +
        gap; // Two rows of images with padding and gaps

    img.Image mergedImage = img.Image(width, height);

    // Set background color
    img.fill(
      mergedImage,
      img.getColor(
        backgroundColor.red,
        backgroundColor.green,
        backgroundColor.blue,
      ),
    );

    // Copy images to the merged image in a 2x2 grid with gaps
    img.copyInto(mergedImage, images[0], dstX: gap, dstY: gap);
    img.copyInto(mergedImage, images[1],
        dstX: imageWidth + (2 * gap), dstY: gap);
    img.copyInto(mergedImage, images[2],
        dstX: gap, dstY: imageHeight + (2 * gap));
    img.copyInto(mergedImage, images[3],
        dstX: imageWidth + (2 * gap), dstY: imageHeight + (2 * gap));

    // SnapIT 이미지 복사
    img.copyInto(
      mergedImage,
      logoImage,
      dstX: (mergedImage.width - logoImage.width) ~/ 2,
      dstY: (imageHeight * 2) + (3 * gap),
    );

    Directory dic = await getApplicationDocumentsDirectory();
    String filename = '${dic.path}/merged_${DateTime.now()}.png';
    File(filename).writeAsBytesSync(img.encodePng(mergedImage));
    return filename;
  }
}
