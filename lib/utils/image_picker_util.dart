import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'image_crop.dart';

class ImagePickerUtil {
  static Future<img.Image> cropAndResizeImage(File imageFile, double aspectRatio) async {
    // 이미지 파일을 로드
    List<int> imageBytes = await imageFile.readAsBytes();
    img.Image originalImage = img.decodeImage(imageBytes)!;

    // 이미지 크기와 비율 계산
    int originalWidth = originalImage.width;
    int originalHeight = originalImage.height;
    int targetWidth, targetHeight;

    // 비율에 맞게 타겟 크기 설정
    if (originalWidth / originalHeight > aspectRatio) {
      targetHeight = originalHeight;
      targetWidth = (originalHeight * aspectRatio).round();
    } else {
      targetWidth = originalWidth;
      targetHeight = (originalWidth / aspectRatio).round();
    }

    // 중앙에서 이미지 크롭
    int offsetX = (originalWidth - targetWidth) ~/ 2;
    int offsetY = (originalHeight - targetHeight) ~/ 2;
    img.Image croppedImage = img.copyCrop(originalImage, offsetX, offsetY, targetWidth, targetHeight);

    // 필요한 경우 이미지 크기 조정
    return croppedImage;
  }

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

      // Apply cropping and resizing
      List<File> processedFiles = [];
      for (var file in imageFiles) {
        // img.Image croppedImage = await cropAndResizeImage(file, 4 / 3);
        img.Image croppedImage = await cropImage(file, 4 / 3);
        File processedFile = File(file.path)..writeAsBytesSync(img.encodeJpg(croppedImage));
        processedFiles.add(processedFile);
      }

      // Enforce the limit of maxImages
      if (currentImages.length + processedFiles.length > maxImages) {
        processedFiles = processedFiles.sublist(0, remainingImages);
      }

      return currentImages + processedFiles;
    }

    return currentImages;
  }
}
