import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:snapit/services/deepai_api_service.dart';
import 'dart:convert';
import 'frame_selection_screen.dart';

class ChangeStyleOfUploadedImageScreen extends StatefulWidget {
  final CameraDescription camera;

  ChangeStyleOfUploadedImageScreen({required this.camera});

  @override
  _ChangeStyleOfUploadedImageScreenState createState() =>
      _ChangeStyleOfUploadedImageScreenState();
}

class _ChangeStyleOfUploadedImageScreenState
    extends State<ChangeStyleOfUploadedImageScreen> {
  final DeepAiApiService deepAiApiService = DeepAiApiService();
  List<File> uploadedImages = [];
  List<String> processedImageUrls = [];
  TextEditingController _textController = TextEditingController();
  bool isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        uploadedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _processImages() async {
    setState(() {
      isLoading = true;
    });

    for (var imageFile in uploadedImages) {
      try {
        final aiSelfieResponse = await deepAiApiService.aiSelfieGenerator(
          imageFile: imageFile,
          text: _textController.text,
        );
        final aiSelfieData = json.decode(aiSelfieResponse);
        final aiSelfieImageUrl = aiSelfieData['output_url'];

        final removeBgResponse =
            await deepAiApiService.removeBackground(aiSelfieImageUrl);
        final removeBgData = json.decode(removeBgResponse);
        final removeBgImageUrl = removeBgData['output_url'];

        processedImageUrls.add(removeBgImageUrl);
      } catch (e) {
        print('Error processing image: $e');
      }
    }

    setState(() {
      isLoading = false;
    });

    if (processedImageUrls.length == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FrameSelectionScreen(
            camera: widget.camera,
            overlayImages: processedImageUrls,
          ),
        ),
      );
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
