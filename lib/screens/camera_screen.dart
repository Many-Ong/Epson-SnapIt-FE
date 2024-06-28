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
                    aspectRatio: 4 / 3, // 부모 위젯의 비율을 1:1로 유지
                    child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Container(
                          width: _controller.value.previewSize!.height,
                          height: _controller.value.previewSize!.width,
                          child: CameraPreview(_controller), // This is your camera preview
                        ),
                      ),
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
                            fit: BoxFit.contain,
                          )
                        : flutter.Image.file(
                            File(widget.overlayImages[overlayIndex]),
                            fit: BoxFit.contain,
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
    img.Image croppedImage = img.copyCrop(flippedImage, startX, startY, targetWidth, targetHeight);

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
      height:
          (croppedImage.width * overlayImage.height / overlayImage.width).round(),
    );

    int offsetX = (croppedImage.width - resizedOverlayImage.width) ~/ 2;
    int offsetY = (croppedImage.height - resizedOverlayImage.height) ~/ 2;
    img.copyInto(croppedImage, resizedOverlayImage,
        dstX: offsetX, dstY: offsetY);

    String newPath = '${file.parent.path}/merged_${DateTime.now()}.png';
    File newImageFile = File(newPath)
      ..writeAsBytesSync(img.encodePng(croppedImage));
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

    ByteData logoData = await rootBundle.load('assets/logo.png');
    img.Image logoImage = img.decodeImage(logoData.buffer.asUint8List())!;


    int width = images[0].width;
    int height = images.fold(0, (prev, element) => prev + element.height) + logoImage.height;

    img.Image mergedFourImage = img.Image(width + 80, height + 270);

    // Set background color
    img.fill(
        mergedFourImage,
        img.getColor(
            backgroundColor.red, backgroundColor.green, backgroundColor.blue));

    int offsetY = 40;
    for (img.Image image in images) {
      img.copyInto(mergedFourImage, image, dstX: 40, dstY: offsetY);
      offsetY += (image.height + 40);
    }
    // SnapIT 이미지를 하단에 복사
    img.copyInto(mergedFourImage, logoImage,
    dstX: (mergedFourImage.width - logoImage.width) ~/ 2, dstY: offsetY + 20);

    Directory dic = await getApplicationDocumentsDirectory();
    String filename = '${dic.path}/merged_${DateTime.now()}.png';
    File(filename).writeAsBytesSync(img.encodePng(mergedFourImage));
    return filename;
  }
}
