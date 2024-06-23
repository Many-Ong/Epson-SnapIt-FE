import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'print_screen.dart';

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  DisplayPictureScreen(
      {required this.imagePath, required BuildContext context});

  Future<void> saveImageToGallery() async {
    final result = await Permission.storage.request();
    if (result.isGranted) {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(imageBytes);
      print('Image saved to gallery: $result');
    } else {
      print('Permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display the Picture'),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            color: Colors.black,
            child: Image.file(
              File(imagePath),
              fit: BoxFit
                  .cover, // Ensure the image fits within the bounds without distortion
            ),
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PrintScreen(imagePath: imagePath),
                  ),
                );
              },
              child: Icon(Icons.print, color: Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 80.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () async {
                  await saveImageToGallery();
                },
                child: Icon(Icons.download, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
