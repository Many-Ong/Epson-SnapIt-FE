import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'package:camera/camera.dart';
import 'package:snapit/services/deepai_api_service.dart';
import 'image_upload_screen.dart';
import 'dart:convert';

class FrameSelectionScreen extends StatefulWidget {
  final CameraDescription camera;

  FrameSelectionScreen({super.key, required this.camera});

  @override
  _FrameSelectionScreenState createState() => _FrameSelectionScreenState();
}

class _FrameSelectionScreenState extends State<FrameSelectionScreen> {
  final List<Color> frameColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.lightBlue,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.blue.shade400,
    Colors.green.shade200,
    Colors.teal,
    Colors.brown,
    Colors.grey,
    Colors.black,
    Colors.white,
  ];

  Color selectedFrameColor = Colors.blue; // Default color
  TextEditingController _textController = TextEditingController();

  final DeepAiApiService deepAiApiService = DeepAiApiService();
  List<String> generatedImageUrls = []; // Store generated image URLs
  bool isLoading = false; // Flag to track if images are being generated

  Future<void> generateOverlayImages(String text) async {
    setState(() {
      isLoading = true; // Start loading
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
        final imageWithRemovedBgUrl =
            await deepAiApiService.removeBackground(imageUrl);
        generatedImageUrls.add(imageWithRemovedBgUrl);

        print(
            'Image generated and background removed successfully: $imageWithRemovedBgUrl');
      } catch (e) {
        print('Failed to generate overlay image: $e');
      }
    }

    setState(() {
      isLoading = false; // Stop loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frame Selection'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Choose your favorite Frame',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 10),
              Center(
                child: CustomPaint(
                  size: Size(120, 320),
                  painter: FramePainter(selectedFrameColor),
                ),
              ),
              SizedBox(height: 20),
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
              if (isLoading) ...[
                CircularProgressIndicator(),
              ] else ...[
                ElevatedButton(
                  onPressed: () async {
                    await generateOverlayImages(_textController.text);
                  },
                  child: Text('Generate Overlay Images'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageUploadScreen(
                          camera: widget.camera,
                          frameColor: selectedFrameColor,
                        ),
                      ),
                    );
                  },
                  child: Text('Upload Your Own Images'),
                ),
              ],
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 16.0,
                  children: frameColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFrameColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedFrameColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ElevatedButton(
                  onPressed: isLoading || generatedImageUrls.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CameraScreen(
                                camera: widget.camera,
                                frameColor: selectedFrameColor,
                                overlayImages: generatedImageUrls,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Ready To SHOOT!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FramePainter extends CustomPainter {
  final Color frameColor;

  FramePainter(this.frameColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final double gap = 2;
    final double height = (size.height - 5 * gap) / 4;

    for (int i = 0; i < 4; i++) {
      final double top = i * (height + gap) + gap;
      final rect = Rect.fromLTWH(gap, top, size.width - 2 * gap, height);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is FramePainter && oldDelegate.frameColor != frameColor;
  }
}
