import 'dart:io';
import 'package:flutter/material.dart';
import 'package:snapit/services/remove_background.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ConfirmPhotoScreen extends StatefulWidget {
  final List<String> takenPictures;
  final img.Image backgroundImage;
  final img.Image frame;

  const ConfirmPhotoScreen({
    super.key,
    required this.takenPictures,
    required this.backgroundImage,
    required this.frame,
  });

  @override
  _ConfirmPhotoScreenState createState() => _ConfirmPhotoScreenState();
}

class _ConfirmPhotoScreenState extends State<ConfirmPhotoScreen> {
  final RemoveBackground removeBackground = RemoveBackground();
  final List<String> processedImages = [];
  final List<String> mergedImages = [];
  bool isProcessing = false;
  img.Image finalImage = img.Image(0, 0);
  String finalImagePath = '';

  @override
  void initState() {
    super.initState();
    _processImages();
  }

  Future<void> _processImages() async {
    List<img.Image> processedImages = [];

    setState(() {
      isProcessing = true;
    });

    for (String imagePath in widget.takenPictures) {
      // Step 1: Remove background
      String processedPath = await removeBackground.removeBackground(imagePath);

      // Step 2: Merge with pink background

      ByteData backgroundData = await rootBundle.load('assets/background_apt.png');
      img.Image backgroundImage = img.decodeImage(backgroundData.buffer.asUint8List())!;

      img.Image overlay = img.decodeImage(File(processedPath).readAsBytesSync())!;
      img.Image mergedImage = img.copyResize(overlay, width: backgroundImage.width);

      img.copyInto(backgroundImage, mergedImage, dstX: 0, dstY: 0);
      processedImages.add(backgroundImage);
    }

    // Step 3: Merge 4 images into one
    finalImage = mergeFourImages(processedImages, widget.frame);

    // Step 4: Save final image
    finalImagePath = await saveFinalImage(finalImage);

    setState(() {
        isProcessing = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Photos'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: isProcessing
            ? CircularProgressIndicator()  // Show a loading indicator while processing
            : Image.file(
                    File(finalImagePath),  // Display the saved image
                    fit: BoxFit.cover,
                  )
                
      ),
    );
  }

  img.Image cropImage(img.Image baseImage) {
    int targetWidth, targetHeight;

    // Calculate target width and height based on aspect ratio
    if (baseImage.width / baseImage.height > 3 / 4) {
        targetHeight = baseImage.height;
        targetWidth = (baseImage.height * 3) ~/ 4;
      } else {
        targetWidth = baseImage.width;
        targetHeight = (baseImage.width * 4) ~/ 3;
      }

    int startX = (baseImage.width - targetWidth) ~/ 2;
    int startY = (baseImage.height - targetHeight) ~/ 2;
    img.Image croppedImage =
        img.copyCrop(baseImage, startX, startY, targetWidth, targetHeight);

    return croppedImage;
  }

  Future<String> mergeImage(img.Image backgroundImage, String overlayPath) async {
    img.Image overlayImage;

    try {
      // Load overlay image
      if (overlayPath.startsWith('http')) {
        final response = await http.get(Uri.parse(overlayPath));
        Uint8List bytes = response.bodyBytes;
        overlayImage = img.decodeImage(bytes)!;
      } else {
        overlayImage = img.decodeImage(File(overlayPath).readAsBytesSync())!;
      }

      // Create a copy of the background image to avoid modifying the original
      img.Image backgroundCopy = img.copyCrop(backgroundImage, 0, 0, backgroundImage.width, backgroundImage.height);

      // Resize overlay image
      img.Image resizedOverlayImage = img.copyResize(
        overlayImage,
        width: backgroundCopy.width,
        height: (backgroundCopy.width * overlayImage.height / overlayImage.width).round(),
      );

      int offsetX = (backgroundCopy.width - resizedOverlayImage.width) ~/ 2;
      int offsetY = (backgroundCopy.height - resizedOverlayImage.height) ~/ 2 + 50;
      img.copyInto(backgroundCopy, resizedOverlayImage, dstX: offsetX, dstY: offsetY);

      // Save merged image as PNG
      String newPath = '${(await getTemporaryDirectory()).path}/final_merged_image_${DateTime.now().millisecondsSinceEpoch}.png';
      File finalMergedImageFile = File(newPath);

      // Encode and write as PNG
      await finalMergedImageFile.writeAsBytes(img.encodePng(backgroundCopy));

      // Return the file path if saving is successful
      return finalMergedImageFile.path;
    } catch (e) {
      print("Error merging image: $e");
      return '';  // Return an empty path if an error occurs
    }
  }

  img.Image mergeFourImages(List<img.Image> images, img.Image frame) {
    int gap = 80; // Gap between images
    int margin = 60; // Margin around the images

    // Ensure all images have the same width and height
    int imageWidth = images[0].width;
    int imageHeight = images[0].height;

    // Calculate the dimensions for the combined image (2x2 grid)
    int width =
          (imageWidth * 2) + gap + (2 * margin); // Two images wide plus gap
      int height =
          (imageHeight * 2) + gap + (2 * margin); // Two images tall plus gap

    img.Image combinedImage = img.Image(width, height + 356);

    // Place the images in a 2x2 grid
    for (int i = 0; i < images.length; i++) {
      int offsetX = (i % 2) * (imageWidth + gap) + margin; // Column position
      int offsetY = (i ~/ 2) * (imageHeight + gap) + margin; // Row position
      img.copyInto(combinedImage, images[i], dstX: offsetX, dstY: offsetY);
    }

    img.copyInto(combinedImage, frame,
            dstX: (combinedImage.width - frame.width) ~/ 2,
            dstY: (combinedImage.height - frame.height) ~/ 2);

    return combinedImage;
  }

  Future<String> saveFinalImage(img.Image finalImage) async {
    String path = '${(await getTemporaryDirectory()).path}/final_image_${DateTime.now().millisecondsSinceEpoch}.png';
    File finalImageFile = File(path)..writeAsBytesSync(img.encodePng(finalImage));

    // Save to gallery
    final File imageFile = File(path);
    final result = await ImageGallerySaver.saveFile(imageFile.path);
    print('Saved to gallery: $result');

    return finalImageFile.path;
  }

}
