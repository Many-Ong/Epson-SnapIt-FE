import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:snapit/services/deepai_api_service.dart';
import 'frame_selection_screen.dart';

class TextToImageScreen extends StatefulWidget {
  final CameraDescription camera;

  TextToImageScreen({super.key, required this.camera});

  @override
  _TextToImageScreenState createState() => _TextToImageScreenState();
}

class _TextToImageScreenState extends State<TextToImageScreen> {
  TextEditingController _textController = TextEditingController();
  final DeepAiApiService deepAiApiService = DeepAiApiService();
  List<String> generatedImageUrls = [];
  bool isLoading = false;

  Future<void> generateOverlayImages(String text) async {
    setState(() {
      isLoading = true;
    });

    const List<String> locations = [
      'right side of the image',
      'left side of the image'
    ];
    const List<String> actions = [
      'jumping',
      'running',
      'sitting',
      'standing',
      'walking',
      'sleeping'
    ];

    final random = Random();

    for (int i = 0; i < 4; i++) {
      final randomLocation = locations[random.nextInt(locations.length)];
      final randomAction = actions[random.nextInt(actions.length)];
      print(
          'Generating overlay image with text: $text $randomAction $randomLocation');

      try {
        final response = await deepAiApiService.text2img(
            text: '$text $randomAction placed on the $randomLocation');
        final responseData = json.decode(response);
        final imageUrl = responseData['output_url'];

        // Remove background from generated image
        final removeBgResponse =
            await deepAiApiService.removeBackground(imageUrl);
        final removeBgData = json.decode(removeBgResponse);
        final removeBgImageUrl = removeBgData['output_url'];

        generatedImageUrls.add(removeBgImageUrl);

        print(
            'Image generated and background removed successfully: $removeBgImageUrl');
      } catch (e) {
        print('Failed to generate overlay image: $e');
      }
    }

    setState(() {
      isLoading = false;
    });

    if (generatedImageUrls.length == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FrameSelectionScreen(
            camera: widget.camera,
            overlayImages: generatedImageUrls,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Images with Text'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Enter text for overlay',
                ),
              ),
            ),
            SizedBox(height: 20),
            if (isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () async {
                  await generateOverlayImages(_textController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: Text('Generate Overlay Images'),
              ),
          ],
        ),
      ),
    );
  }
}
