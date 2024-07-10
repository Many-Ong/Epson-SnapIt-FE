import 'package:flutter/material.dart';
import 'camera_screen.dart';

class FrameSelectionScreen extends StatefulWidget {
  final List<String> overlayImages;

  FrameSelectionScreen({super.key, required this.overlayImages});

  @override
  _FrameSelectionScreenState createState() => _FrameSelectionScreenState();
}

class _FrameSelectionScreenState extends State<FrameSelectionScreen> {
  final List<Color> frameColors = [
    Color.fromARGB(255, 255, 200, 221),
    Color.fromARGB(255, 255, 175, 204),
    Color.fromARGB(255, 255, 173, 173),
    Color.fromARGB(255, 255, 214, 165),
    Color.fromARGB(255, 253, 255, 182),
    Color.fromARGB(255, 202, 255, 191),
    Color.fromARGB(255, 189, 224, 254),
    Color.fromARGB(255, 162, 210, 255),
    Color.fromARGB(255, 160, 196, 255),
    Color.fromARGB(255, 189, 178, 255),
    Color.fromARGB(255, 205, 180, 219),
    Color.fromARGB(255, 192, 192, 192),
    Colors.black,
    Colors.white,
  ];

  Color selectedFrameColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Frame Color'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Choose your favorite Frame',
              style: TextStyle(fontSize: 16, color: Colors.white),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        overlayImages: widget.overlayImages,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
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
