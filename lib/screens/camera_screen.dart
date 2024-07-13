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
  final List<String> overlayImages;

  const CameraScreen({
    super.key,
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
  List<String> takenPictures = [];
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
    _controller = CameraController(frontCamera, ResolutionPreset.veryHigh);
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

   @override
  Widget build(BuildContext context) { 
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: <Widget>[
                    Center(
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: ClipRect(
                          child: Transform.scale(
                            scale: _controller.value.aspectRatio / 3 * 4,
                            child: Center(
                              child: CameraPreview(
                                _controller),
                            )
                          ),
                          ),
                        ),
                    ),
                    Center(
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: widget.overlayImages[overlayIndex].startsWith('http')
                            ? flutter.Image.network(
                                widget.overlayImages[overlayIndex],
                                fit: BoxFit.cover, // 이미지가 프리뷰 화면을 덮도록 설정
                              )
                            : flutter.Image.file(
                                File(widget.overlayImages[overlayIndex]),
                                fit: BoxFit.cover, // 이미지가 프리뷰 화면을 덮도록 설정
                              ),
                      ),
                    ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Container(
                      padding:
                          EdgeInsets.all(4), // Add padding inside the container
                      width: 70, // Set the size to match the iOS camera button
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width:
                              2, // Set the border width to match iOS camera button
                        ),
                      ),
                      child: FloatingActionButton(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(45),
                        ),
                        onPressed: () async {
                          try {
                            await _initializeControllerFuture; // Ensure the future is complete before proceeding
                            if (pictureCount < 4) {
                              final XFile image =
                                  await _controller.takePicture();
                              String overlayImagePath = await mergeImage(
                                  image, widget.overlayImages[overlayIndex]);
                              takenPictures.add(overlayImagePath);
                              changeOverlayImage();
                              pictureCount++;

                              img.Image logoImage = img.decodeImage(
                                  (await rootBundle
                                          .load('assets/logo_black.png'))
                                      .buffer
                                      .asUint8List())!;

                              img.Image mergedFourImage =
                                  await mergeFourImages();

                              if (pictureCount == 4) {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => DisplayPictureScreen(
                                      mergedFourImage: mergedFourImage,
                                      logoImage: logoImage,
                                      context: context,
                                    ),
                                  ),
                                );
                                pictureCount = 0;
                                takenPictures.clear();
                              }
                            }
                          } catch (e) {
                            print(e);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
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

    img.Image resizedOverlayImage = img.copyResize(
      overlayImage,
      width: croppedImage.width,
      height: (croppedImage.width * overlayImage.height / overlayImage.width)
          .round(),
    );

    int offsetX = (croppedImage.width - resizedOverlayImage.width) ~/ 2;
    int offsetY = (croppedImage.height - resizedOverlayImage.height) ~/ 2 + 50; //임의로 조정
    img.copyInto(croppedImage, resizedOverlayImage,
        dstX: offsetX, dstY: offsetY);

    String newPath = '${file.parent.path}/merged_${DateTime.now()}.png';
    File newImageFile = File(newPath)
      ..writeAsBytesSync(img.encodePng(croppedImage));
    print('New image saved at: $newPath');
    return newImageFile.path;
  }

  Future<img.Image> mergeFourImages() async {
    List<img.Image> images = [];
    for (String path in takenPictures) {
      img.Image image = img.decodeImage(File(path).readAsBytesSync())!;
      images.add(image);
    }

    ByteData logoData = await rootBundle.load('assets/logo_black.png');
    img.Image logoImage = img.decodeImage(logoData.buffer.asUint8List())!;

    int imageWidth = images[0].width;
    int imageHeight = images[0].height;
    int gap = 35;

    print('imageWidth: $imageWidth');
    print('imageHeight: $imageHeight');

    int width = (imageWidth * 2) + (7 * gap);
    int height = (imageHeight * 4) + (3 * gap) + logoImage.height + gap;

    print('logoImage width: ${logoImage.width}');
    print('logoImage height: ${logoImage.height}');

    img.Image mergedFourImage = img.Image(width, height + 360);

    int offsetY = 40;
    for (img.Image image in images) {
      img.copyInto(mergedFourImage, image, dstX: gap * 2, dstY: offsetY);
      offsetY += (image.height + 2 * gap);
    }

    img.copyInto(mergedFourImage, mergedFourImage,
        dstX: mergedFourImage.width ~/ 2, dstY: 0);

    img.copyInto(mergedFourImage, mergedFourImage,
        dstX: mergedFourImage.width ~/ 2, dstY: 0);

    return mergedFourImage;
  }
}