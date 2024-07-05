import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:snapit/screens/deepai_api_service.dart';
import 'dart:convert';
import 'frame_selection_screen.dart';
import 'dart:math';
import '../utils/image_picker_util.dart';

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

  Future<void> _pickImages() async {
    uploadedImages =
        await ImagePickerUtil.pickImages(context, uploadedImages, 4);
    setState(() {});
  }

  Future<void> _processImages() async {
    setState(() {
      isLoading = true;
    });

    final random = Random();

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

    print('Generated image URLs: $processedImageUrls');

    if (processedImageUrls.length != 4) {
      // Add random images to fill the list
      while (processedImageUrls.length < 4) {
        String tmpImageUrls =
            processedImageUrls[random.nextInt(processedImageUrls.length)];
        processedImageUrls.add(tmpImageUrls);
      }
    }

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
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: Text('Upload Image'),
            ),
            SizedBox(height: 10),
            Text(
              '${uploadedImages.length}/4 selected',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                itemCount: uploadedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Image.file(uploadedImages[index]),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              uploadedImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
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
