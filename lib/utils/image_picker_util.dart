import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  static Future<List<File>> pickImages(
      BuildContext context, List<File> currentImages, int maxImages) async {
    int remainingImages = maxImages - currentImages.length;
    if (remainingImages <= 0) {
      // Show a message if the limit is reached
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only upload up to $maxImages images.'),
        ),
      );
      return currentImages;
    }

    // Pick images
    final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      List<File> imageFiles =
          pickedFiles.map((file) => File(file.path)).toList();

      // Enforce the limit of maxImages
      if (currentImages.length + imageFiles.length > maxImages) {
        imageFiles = imageFiles.sublist(0, remainingImages);
      }

      return currentImages + imageFiles;
    }

    return currentImages;
  }
}
