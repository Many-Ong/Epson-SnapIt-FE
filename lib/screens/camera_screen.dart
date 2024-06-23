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
    _initializeControllerFuture = _controller.initialize().then((_) async {
      if (!mounted) return;
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
                    aspectRatio: 4 / 3,
                    child: CameraPreview(_controller),
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

    int baseWidth = baseImage.width;
    int baseHeight = baseImage.height;

    img.Image overlayImage;
    if (overlayPath.startsWith('http')) {
      final response = await http.get(Uri.parse(overlayPath));
      Uint8List bytes = response.bodyBytes;
      overlayImage = img.decodeImage(bytes)!;
    } else {
      overlayImage = img.decodeImage(File(overlayPath).readAsBytesSync())!;
    }

    img.Image resizedFlippedImage = img.copyResize(
      flippedImage,
      width: 4 * baseHeight ~/ 3,
      height: baseHeight,
    );

    img.Image resizedOverlayImage = img.copyResize(
      overlayImage,
      width: resizedFlippedImage.width,
      height:
          (resizedFlippedImage.width * overlayImage.height / overlayImage.width)
              .round(),
    );

    int offsetX = (resizedFlippedImage.width - resizedOverlayImage.width) ~/ 2;
    int offsetY =
        (resizedFlippedImage.height - resizedOverlayImage.height) ~/ 2;
    img.copyInto(resizedFlippedImage, resizedOverlayImage,
        dstX: offsetX, dstY: offsetY);

    String newPath = '${file.parent.path}/merged_${DateTime.now()}.png';
    File newImageFile = File(newPath)
      ..writeAsBytesSync(img.encodePng(resizedFlippedImage));
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

    int width = images[0].width;
    int height = images.fold(0, (prev, element) => prev + element.height);

    img.Image mergedFourImage = img.Image(width + 160, height + 300);

    // Set background color
    img.fill(
        mergedFourImage,
        img.getColor(
            backgroundColor.red, backgroundColor.green, backgroundColor.blue));

    int offsetY = 60;
    for (img.Image image in images) {
      img.copyInto(mergedFourImage, image, dstX: 80, dstY: offsetY);
      offsetY += (image.height + 60);
    }

    Directory dic = await getApplicationDocumentsDirectory();
    String filename = '${dic.path}/merged_${DateTime.now()}.png';
    File(filename).writeAsBytesSync(img.encodePng(mergedFourImage));
    return filename;
  }
}
