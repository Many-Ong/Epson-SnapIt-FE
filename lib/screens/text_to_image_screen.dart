import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:snapit/screens/camera_screen.dart';
import 'package:snapit/screens/deepai_api_service.dart';
//테스트용 파일 추가
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TextToImageScreen extends StatefulWidget {
  TextToImageScreen({
    super.key,
  });

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

    List<String> localGeneratedImageUrls = [];

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

        localGeneratedImageUrls.add(removeBgImageUrl);

        print(
            'Image generated and background removed successfully: $removeBgImageUrl');
      } catch (e) {
        print('Failed to generate overlay image: $e');
      }
    }

    setState(() {
      generatedImageUrls = localGeneratedImageUrls;
      isLoading = false;
    });

    print('Generated image URLs: $generatedImageUrls');

    if (generatedImageUrls.length != 4) {
      // Add random images to fill the list
      while (generatedImageUrls.length < 4) {
        String tmpImageUrls =
            generatedImageUrls[random.nextInt(generatedImageUrls.length)];
        generatedImageUrls.add(tmpImageUrls);
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          overlayImages: generatedImageUrls,
        ),
      ),
    );
  }

  Future<File> copyAssetToFile(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${assetPath.split('/').last}';
    final file = File(filePath);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
  }

  Future<bool> testAssetImage() async {
    setState(() {
      isLoading = true;
    });

    List<String> tempGeneratedImageUrls = [];

    for (int i = 1; i <= 4; i++) {
      File localImageFile = await copyAssetToFile('assets/Image1_$i.png');
      if (localImageFile != null) {
        tempGeneratedImageUrls.add(localImageFile.path); // 파일 경로를 임시 리스트에 추가
      }
    }

    setState(() {
      generatedImageUrls = tempGeneratedImageUrls;
      isLoading = false;
    });

    if (generatedImageUrls.length == 4) {
      print("Success!");
      return true;
    } else {
      print("Failed!");
      return false;
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
              Column(
                children: [
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
                  SizedBox(height: 10), // 버튼 사이의 간격을 위한 SizedBox
                  ElevatedButton(
                    onPressed: () async {
                      bool success = await testAssetImage();
                      if (success) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CameraScreen(
                                    overlayImages: generatedImageUrls,
                                  )),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: Text('Test with Default Images'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
