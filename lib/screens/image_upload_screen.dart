import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import 'package:camera/camera.dart';

class ImageUploadScreen extends StatefulWidget {
  final CameraDescription camera;
  final Color frameColor;

  ImageUploadScreen({required this.camera, required this.frameColor});

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  List<File> uploadedImages = [];

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        uploadedImages.add(File(pickedFile.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Images'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Upload Image'),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                itemCount: uploadedImages.length,
                itemBuilder: (context, index) {
                  return Image.file(uploadedImages[index]);
                },
              ),
            ),
            ElevatedButton(
              onPressed: uploadedImages.length == 4
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(
                            camera: widget.camera,
                            frameColor: widget.frameColor,
                            overlayImages: uploadedImages
                                .map((file) => file.path)
                                .toList(),
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text('Ready To SHOOT!'),
            ),
          ],
        ),
      ),
    );
  }
}
