import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
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
  String? overlayImageUrl;

  Future<void> generateOverlayImage(String text) async {
    // Replace with your AI service URL and request format
    final response = await http.post(
      Uri.parse('https://api.your-ai-service.com/generate-overlay'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        overlayImageUrl = data['imageUrl'];
      });
    } else {
      // Handle error
      print('Error generating overlay image: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frame Selection'),
        centerTitle: true,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    generateOverlayImage(_textController.text);
                  },
                  child: Text('Generate Overlay Image'),
                ),
              ),
              if (overlayImageUrl != null) ...[
                SizedBox(height: 20),
                Image.network(overlayImageUrl!),
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
                  onPressed: () {
                    if (overlayImageUrl != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(
                            camera: widget.camera,
                            frameColor: selectedFrameColor,
                            overlayImageUrl: overlayImageUrl!,
                          ),
                        ),
                      );
                    }
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
