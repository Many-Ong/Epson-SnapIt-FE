import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'frame_selection_screen.dart';
import 'dart:math';
import 'package:local_rembg/local_rembg.dart';

class RemoveBackGroundScreen extends StatefulWidget {
  final CameraDescription camera;

  RemoveBackGroundScreen({required this.camera});

  @override
  _RemoveBackGroundScreenState createState() =>
      _RemoveBackGroundScreenState();
}

class _RemoveBackGroundScreenState extends State<RemoveBackGroundScreen> {
  List<File> uploadedImages = [];
  List<String> processedImageUrls = [];
  TextEditingController _textController = TextEditingController();
  bool isLoading = false;
  Uint8List? imageBytes;
  String? message;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        uploadedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<String> _saveImageToFileSystem(Uint8List imageBytes) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String fileName = "processed_${DateTime.now().millisecondsSinceEpoch}.png";
    File file = File('${directory.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  Future<void> _processImages() async {
    setState(() {
      isLoading = true;
    });

    final random = Random();
    List<String> processedImageUrls = [];

    for (var imageFile in uploadedImages) {
      try {
        LocalRembgResultModel localRembgResultModel =
            await LocalRembg.removeBackground(imagePath: imageFile.path); 
        if (localRembgResultModel.status == 1) {
          Uint8List imageBytes = Uint8List.fromList(localRembgResultModel.imageBytes!);
          String imageUrl = await _saveImageToFileSystem(imageBytes);
          processedImageUrls.add(imageUrl);
        } else {
          throw Exception('Background removal failed: ${localRembgResultModel.errorMessage}');
        }
      } catch (e) {
        print('Error processing image: $e');
      }
    }

    setState(() {
      isLoading = false;
    });

    print('Generated image URLs: $processedImageUrls');

    if (processedImageUrls.length >= 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FrameSelectionScreen(
            camera: widget.camera,
            overlayImages: processedImageUrls,
          ),
        ),
      );
    } else {
      // Handle the error or inform the user
      print('Not enough images processed successfully.');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload and Style Images'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Enter style description',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
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
            if (isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: uploadedImages.length == 4 && !isLoading
                    ? () async {
                        await _processImages();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: Text('Process and Continue'),
              ),
          ],
        ),
      ),
    );
  }
}
