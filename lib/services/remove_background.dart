import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snapit/screens/camera_screen.dart';
import 'dart:math';
import 'package:local_rembg/local_rembg.dart';
import '../utils/image_picker_util.dart';
import 'package:flutter/cupertino.dart';

class RemoveBackground {
    Future<String> _saveImageToFileSystem(Uint8List imageBytes) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String fileName = "processed_${DateTime.now().millisecondsSinceEpoch}.png";
    File file = File('${directory.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  Future<String> removeBackground(String imagePath) async {
    try {
      LocalRembgResultModel localRembgResultModel =
          await LocalRembg.removeBackground(imagePath: imagePath);
      if (localRembgResultModel.status == 1) {
        Uint8List imageBytes =
            Uint8List.fromList(localRembgResultModel.imageBytes!);
        String imageUrl = await _saveImageToFileSystem(imageBytes);
        return imageUrl;
      } else {
        throw Exception(
            'Background removal failed: ${localRembgResultModel.errorMessage}');
      }
    } catch (e) {
        return '';
    }
  }
}