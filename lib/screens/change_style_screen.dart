import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import 'package:camera/camera.dart';
import '../utils/image_picker_util.dart';

class ChangeStyleScreen extends StatefulWidget {
  final CameraDescription camera;
  final Color frameColor;

  ChangeStyleScreen({required this.camera, required this.frameColor});

  @override
  _ChangeStyleScreenState createState() => _ChangeStyleScreenState();
}

class _ChangeStyleScreenState extends State<ChangeStyleScreen> {
  List<File> uploadedImages = [];

  Future<void> _pickImages() async {
    uploadedImages =
        await ImagePickerUtil.pickImages(context, uploadedImages, 4);
    setState(() {});
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
              onPressed: uploadedImages.length < 4 ? _pickImages : null,
              child: Text('Upload Images'),
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
