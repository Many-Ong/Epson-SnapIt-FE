import 'dart:async'; // Import for Timer
import 'dart:io';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/material.dart' as flutter;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:snapit/screens/display_picture_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
  final List<String> overlayImages;
  final bool isBasicFrame;
  final bool isSpecialFrame;
  final String grid;

  const CameraScreen({
    super.key,
    required this.overlayImages,
    required this.isBasicFrame,
    required this.isSpecialFrame,
    required this.grid,
  });

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<CameraDescription> cameras = [];
  int pictureCount = 0;
  List<String> takenPictures = [];
  int overlayIndex = 0;
  img.Image logoImage = img.Image(0, 0);
  img.Image duplicatedLogoImage = img.Image(0, 0);
  img.Image frame = img.Image(0, 0);

  Timer? _timer; // Timer object for countdown
  int _countdown = 7; // Countdown start value
  bool isShowingTakenPhoto = false; // Flag to show the taken photo
  bool isFlashing = false; // Flag for flash effect

  late AnimationController
      _flashController; // Animation controller for flash effect
  late Animation<double> _flashAnimation; // Animation for flash effect

  @override
  void initState() {
    super.initState();
    initCamera();
    loadLogoImage();
    loadFrameImage();

    // Initialize the flash animation controller
    _flashController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100), // Duration for flash effect
    );

    _flashAnimation = Tween<double>(begin: 1, end: 0).animate(_flashController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            isFlashing = false; // Hide flash effect after animation completes
          });
        }
      });
  }

  Future<void> loadLogoImage() async {
    ByteData logoData = await rootBundle.load('assets/logo_black.png');
    logoImage = img.decodeImage(logoData.buffer.asUint8List())!;

    // Initialize the duplicated logo image
    int duplicatedLogoWidth = (logoImage.width * 2);
    duplicatedLogoImage = img.Image(duplicatedLogoWidth, logoImage.height);

    // Copy the logo into the new duplicated logo image twice
    img.copyInto(duplicatedLogoImage, logoImage, dstX: 0, dstY: 0);
    img.copyInto(duplicatedLogoImage, logoImage,
        dstX: duplicatedLogoWidth - logoImage.width, dstY: 0);
  }

  Future<void> loadFrameImage() async {
    ByteData frameData = await rootBundle.load('assets/frame_special_1.png');
    frame = img.decodeImage(frameData.buffer.asUint8List())!;
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    CameraDescription frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _controller = CameraController(frontCamera, ResolutionPreset.veryHigh,
        enableAudio: false);
    _initializeControllerFuture = _controller.initialize().then((_) async {
      if (!mounted) return;
      await _controller.setExposureMode(ExposureMode.auto);
      await _controller.setFlashMode(FlashMode.off);
      setState(() {
        startTimer(); // Start the timer when the camera is initialized
      });
    }).catchError((error) {
      print('Error initializing camera: $error');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel(); // Cancel the timer when disposing
    _flashController.dispose(); // Dispose the flash animation controller
    super.dispose();
  }

  void changeOverlayImage() {
    setState(() {
      overlayIndex = (overlayIndex + 1) % widget.overlayImages.length;
    });
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
        takePhoto(); // Automatically take a photo when countdown reaches zero
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void resetTimer() {
    _timer?.cancel();
    setState(() {
      _countdown = 7;
    });
  }

  Future<void> takePhoto() async {
    try {
      await _initializeControllerFuture;
      if (pictureCount < 4) {
        final XFile image = await _controller.takePicture();
        String takenPicture = widget.isBasicFrame
            ? await cropAndSaveImage(image)
            : await mergeImage(image, widget.overlayImages[overlayIndex]);
        takenPictures.add(takenPicture);
        if (!widget.isBasicFrame) changeOverlayImage();

        // Trigger the flash effect
        setState(() {
          isFlashing = true;
        });
        _flashController.forward(from: 0);

        // Show the taken picture for 2 seconds
        setState(() {
          isShowingTakenPhoto = true; // Set flag to true to show taken photo
        });

        if (pictureCount != 3) {
          // Display the image for 1 seconds
          await Future.delayed(Duration(seconds: 1));
        } else {
          await Future.delayed(Duration(milliseconds: 200));
        }

        setState(() {
          isShowingTakenPhoto = false; // Hide the taken photo and resume camera
        });

        img.Image mergedFourImage = !widget.isBasicFrame || widget.grid == '4x1'
            ? await mergeFourImages('4x1')
            : await mergeFourImages('2x2');

        if (pictureCount != 3) {
          setState(() {
            pictureCount = pictureCount + 1;
            resetTimer(); // Reset the timer after taking a photo
            startTimer(); // Restart the timer
          });
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DisplayPictureScreen(
                mergedFourImage: mergedFourImage,
                isSpecialFrame: widget.isSpecialFrame,
                context: context,
              ),
            ),
          );
          pictureCount = 0;
          takenPictures.clear();
          resetTimer(); // Reset the timer after the last photo
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            '${pictureCount + 1}/4',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )),
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: <Widget>[
                Center(
                  heightFactor: 1,
                  child: Text(
                    isShowingTakenPhoto
                        ? ''
                        : '$_countdown', // Display the countdown
                    style: TextStyle(color: Colors.white, fontSize: 60),
                  ),
                ),
                if (isShowingTakenPhoto)
                  // Show the last taken photo for 2 seconds
                  if ((!widget.isBasicFrame || widget.grid == '4x1'))
                    Positioned(
                      top: -110,
                      left: 0,
                      right: 0,
                      child: flutter.Image.file(
                        File(takenPictures.last),
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                      ),
                    ),
                if (isShowingTakenPhoto)
                  if (widget.isBasicFrame && widget.grid == '2x2')
                    Center(
                      heightFactor: 2,
                      child: flutter.Image.file(
                        File(takenPictures.last),
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                      ),
                    ),
                if (!isShowingTakenPhoto &&
                    (!widget.isBasicFrame || widget.grid == '4x1'))
                  Positioned(
                    top: 160,
                    left: 0,
                    right: 0,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ClipRect(
                        child: Transform.scale(
                            scale: _controller.value.aspectRatio / 3 * 4,
                            child: Center(
                              child: CameraPreview(_controller),
                            )),
                      ),
                    ),
                  ),
                if (!isShowingTakenPhoto && !widget.isBasicFrame)
                  Center(
                    heightFactor: 2,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child:
                          widget.overlayImages[overlayIndex].startsWith('http')
                              ? flutter.Image.network(
                                  widget.overlayImages[overlayIndex],
                                  fit: BoxFit.cover,
                                )
                              : flutter.Image.file(
                                  File(widget.overlayImages[overlayIndex]),
                                  fit: BoxFit.cover,
                                ),
                    ),
                  ),
                if (!isShowingTakenPhoto &&
                    widget.isBasicFrame &&
                    widget.grid == '2x2')
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRect(
                        child: Transform.scale(
                          scale: _controller.value.aspectRatio / 4 * 3,
                          child: Center(
                            child: CameraPreview(_controller),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Flash effect overlay
                if (isFlashing)
                  AnimatedBuilder(
                    animation: _flashAnimation,
                    builder: (context, child) {
                      return Container(
                        color: Colors.white.withOpacity(_flashAnimation.value),
                      );
                    },
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 85),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.all(4),
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: FloatingActionButton(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(45),
                            ),
                            onPressed: () {
                              takePhoto(); // Take photo immediately on button press
                              resetTimer();
                            },
                          ),
                        ),
                      ],
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

  Future<String> cropAndSaveImage(XFile picture) async {
    File file = File(picture.path);

    if (!file.existsSync()) {
      print('File does not exist');
      return '';
    }

    img.Image baseImage = img.decodeImage(file.readAsBytesSync())!;
    img.Image croppedImage =
        cropImage(baseImage, aspectRatio: widget.grid == '2x2' ? '3:4' : '4:3');

    String newPath = '${file.parent.path}/cropped_${DateTime.now()}.png';
    File newImageFile = File(newPath)
      ..writeAsBytesSync(img.encodePng(croppedImage));
    print('New image saved at: $newPath');
    return newImageFile.path;
  }

  img.Image flipImage(img.Image baseImage) {
    img.Image flippedImage = img.flipHorizontal(baseImage);
    return flippedImage;
  }

  img.Image cropImage(img.Image baseImage, {String aspectRatio = '4:3'}) {
    img.Image flippedImage = img.flipHorizontal(baseImage);

    int targetWidth, targetHeight;
    if (aspectRatio == '4:3') {
      if (baseImage.width / baseImage.height > 4 / 3) {
        targetHeight = baseImage.height;
        targetWidth = (baseImage.height * 4) ~/ 3;
      } else {
        targetWidth = baseImage.width;
        targetHeight = (baseImage.width * 3) ~/ 4;
      }
    } else {
      if (baseImage.width / baseImage.height > 3 / 4) {
        targetHeight = baseImage.height;
        targetWidth = (baseImage.height * 3) ~/ 4;
      } else {
        targetWidth = baseImage.width;
        targetHeight = (baseImage.width * 4) ~/ 3;
      }
    }

    int startX = (baseImage.width - targetWidth) ~/ 2;
    int startY = (baseImage.height - targetHeight) ~/ 2;
    img.Image croppedImage =
        img.copyCrop(flippedImage, startX, startY, targetWidth, targetHeight);

    return croppedImage;
  }

  Future<String> mergeImage(XFile picture, String overlayPath) async {
    File file = File(picture.path);

    if (!file.existsSync()) {
      print('File does not exist');
      return '';
    }

    img.Image baseImage = img.decodeImage(file.readAsBytesSync())!;
    img.Image croppedImage =
        cropImage(baseImage, aspectRatio: widget.grid == '2x2' ? '4:3' : '3:4');

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
    int offsetY = (croppedImage.height - resizedOverlayImage.height) ~/ 2 + 50;
    img.copyInto(croppedImage, resizedOverlayImage,
        dstX: offsetX, dstY: offsetY);

    String newPath = '${file.parent.path}/merged_${DateTime.now()}.png';
    File newImageFile = File(newPath)
      ..writeAsBytesSync(img.encodePng(croppedImage));
    print('New image saved at: $newPath');
    return newImageFile.path;
  }

  Future<img.Image> mergeFourImages(String grid) async {
    List<img.Image> images = [];
    for (String path in takenPictures) {
      img.Image image = img.decodeImage(File(path).readAsBytesSync())!;
      images.add(image);
    }

    if (grid == '2x2') {
      int gap = 62; // Gap between images
      int margin = 81; // Margin around the images

      // Resize images to fit in a 2x2 grid without cropping
      int maxWidth =
          images.map((image) => image.width).reduce((a, b) => a > b ? a : b);
      int maxHeight =
          images.map((image) => image.height).reduce((a, b) => a > b ? a : b);

      // Resize images to fit within the grid cells, keeping aspect ratio
      images = images.map((image) {
        return img.copyResize(image, width: (maxWidth), height: (maxHeight));
      }).toList();

      // Define the size of the final image based on resized dimensions and gaps
      int width =
          (maxWidth * 2) + gap + (2 * margin); // Two images wide plus gap
      int height =
          (maxHeight * 2) + gap + (2 * margin); // Two images tall plus gap

      // Create the base image for the 2x2 grid
      img.Image mergedFourImage = img.Image(width, height + 360);

      // Place the images in a 2x2 grid
      for (int i = 0; i < images.length; i++) {
        int offsetX = (i % 2) * (maxWidth + gap) + gap; // Column position
        int offsetY = (i ~/ 2) * (maxHeight + gap) + gap; // Row position
        img.copyInto(mergedFourImage, images[i], dstX: offsetX, dstY: offsetY);
      }

      if (widget.isSpecialFrame) {
        img.copyInto(mergedFourImage, frame,
            dstX: (mergedFourImage.width - frame.width) ~/ 2,
            dstY: (mergedFourImage.height - frame.height) ~/ 2);
      } else {
        img.copyInto(mergedFourImage, duplicatedLogoImage,
            dstX: (mergedFourImage.width - duplicatedLogoImage.width) ~/ 2,
            dstY: mergedFourImage.height - duplicatedLogoImage.height - 120);
      }

      return mergedFourImage;
    } else if (grid == '4x1') {
      int imageWidth = images[0].width;
      int imageHeight = images[0].height;
      int gap = 35;

      int width = (imageWidth * 2) + (7 * gap);
      int height = (imageHeight * 4) + (3 * gap) + logoImage.height + gap;

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

      img.copyInto(mergedFourImage, duplicatedLogoImage,
          dstX: (mergedFourImage.width - duplicatedLogoImage.width) ~/ 2,
          dstY: mergedFourImage.height - duplicatedLogoImage.height - 120);

      return mergedFourImage;
    } else {
      return img.Image(0, 0);
    }
  }
}
