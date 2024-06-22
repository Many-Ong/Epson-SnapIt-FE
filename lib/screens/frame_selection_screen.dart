import 'dart:math';
import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:snapit/services/lime_wire_api_service.dart';

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
  List<String>? overlayImageUrls;
  final LimeWireApiService limeWireApiService = LimeWireApiService();

  Future<void> generateOverlayImage(String text) async {
    const List<String> locations = [
      'right side of the image',
      'left side of the image'
    ];
    final random = Random();
    final randomLocation = locations[random.nextInt(locations.length)];

    print(
        'Generating overlay image with text: $text, random location: $randomLocation');

    try {
      final response = await limeWireApiService.generateImage(
        prompt: '$text placed on the $randomLocation',
        aspectRatio: '3:2',
        negativePrompt: 'darkness, fog',
        samples: 1,
        quality: 'LOW',
        guidanceScale: 50,
        style: 'PHOTOREALISTIC',
        apiVersion: 'v1', // Specify the API version
        accept: 'image/png', // Specify the Accept header
      );

      // const response = {
      //   "id": "5e66adb3-cddc-41c2-959a-b91cdcc5aa84",
      //   "self":
      //       "https://api.limewire.com/api/request/5e66adb3-cddc-41c2-959a-b91cdcc5aa84",
      //   "status": "COMPLETED",
      //   "failure_code": null,
      //   "failure_reason": null,
      //   "credits_used": 3.0,
      //   "credits_remaining": 6.509741,
      //   "data": [
      //     {
      //       "asset_id": "a8b4b1b5-1ba4-4057-92dd-0e69fb845ab1",
      //       "self":
      //           "https://api.limewire.com/api/assets/a8b4b1b5-1ba4-4057-92dd-0e69fb845ab1",
      //       "asset_url":
      //           "https://ai-studio-assets.limewire.media/u/18e5cfac-07bb-40d4-9014-e49dd321ed12/image/60029ac0-0456-44d0-b04b-22db1d015bb4?Expires=1719079179&Signature=ajHzGfEOzVfiZ3MZyil-KZJxktV1WCChYbfGx~Mj39TqmPtbpamGMztMPoaReuW8NshYluImO3Fk5fBwNRwrNH5fWcX2Bj3uGa9jLBnl9s045xpUSub~eCPqSci7uS43SnwM8vYwa~VeNMFfiU20~6t1dGXTwMNk-~s6jIhggVIdTzGb8EaGN-qmQlca85gZejDei03GxH5iNuMXdS1DitAF1670bPkvJbrg5jCoxc54zWZnrgT11X9KZTDzEoUchYVLRic1Au0PoWtsmSYZqOb4kiaxd4ME0GWWyNHjzTaClZwXma9lNqyfp~-OpR9GD0II~A3Gqb3YdFW6IE-nKw__&Key-Pair-Id=K1U52DHN9E92VT",
      //       "type": "image/jpeg",
      //       "width": 1216,
      //       "height": 832
      //     },
      //     {
      //       "asset_id": "d5e69e1c-5269-4f7e-be82-45c8482181ed",
      //       "self":
      //           "https://api.limewire.com/api/assets/d5e69e1c-5269-4f7e-be82-45c8482181ed",
      //       "asset_url":
      //           "https://ai-studio-assets.limewire.media/u/18e5cfac-07bb-40d4-9014-e49dd321ed12/image/938a9024-dc4a-47c4-94eb-3a2e67f7f36e?Expires=1719079179&Signature=mySKyhkOcXuvy62htpg5uBFz7GaZkB1K~L4R7XaNNsJgkpUYldJMYQ6vzANHXaJJ2vsU3afXHth2Rd0bScvqh51JFnJiZE5c~d8oMrlxvNYY0Tg0kW04ysp-qxHSR5sRgxCp7MaTlJDPvXv80Ip9PO~iuVCiUrKxxU41xiQxO866~Uq0-4OJpyINYTwS4F79IiUZpith7~yh5CQQT-GFA6OARSDckJBCVW6NJVeY7hkcwQD1BGaCYqokq9JNXQ74KIyz7QuPzCDDWLLnRqnkvjkgTydJePQKy2S9CsRrny-EWIGPHWBq2Ym7nefBQJAWRIQcW2Ipkga-oUy~7F121Q__&Key-Pair-Id=K1U52DHN9E92VT",
      //       "type": "image/jpeg",
      //       "width": 1216,
      //       "height": 832
      //     },
      //     {
      //       "asset_id": "4ca55f25-1179-4f0d-b6d1-1556483e96f4",
      //       "self":
      //           "https://api.limewire.com/api/assets/4ca55f25-1179-4f0d-b6d1-1556483e96f4",
      //       "asset_url":
      //           "https://ai-studio-assets.limewire.media/u/18e5cfac-07bb-40d4-9014-e49dd321ed12/image/d022067f-3ce6-4e76-980f-7374e851e91d?Expires=1719079179&Signature=tW8A5fIj7SFAUB5gAUkWwtgu2A0TO9sFCf8VOgj0Rf7AdBLfQdQKRHmHlWEqRsLp-dVglSivtlnA9IepOsgwIeVxYGt4~STjGqyQ5vxS59f23x9Aba3CxpJZ4cww4P-gTH~mh-JomXV2RsPTxPPhNXLwEp7KdWA0567-jHtfUNnzbN2h75VHtRAgQpSMcr5vNwyfr48j~j~j-GXDr1XGnfibxUZx2QnypFaRsARlhQ1GCRQLw9K9Iyg~3BkzUuL7oJZgO90RlxFn56P0B-6kq2iDLNfTeE4mVm-aGLEU2aMtIu0LChRwIAy7owfkntMk2JzFEic0GchCUkBAI3bzbg__&Key-Pair-Id=K1U52DHN9E92VT",
      //       "type": "image/jpeg",
      //       "width": 1216,
      //       "height": 832
      //     },
      //     {
      //       "asset_id": "e78dbf84-bd4b-4b4c-a239-c2c62299b7f1",
      //       "self":
      //           "https://api.limewire.com/api/assets/e78dbf84-bd4b-4b4c-a239-c2c62299b7f1",
      //       "asset_url":
      //           "https://ai-studio-assets.limewire.media/u/18e5cfac-07bb-40d4-9014-e49dd321ed12/image/610241d4-88ed-4b7d-abb1-c7fd676c247a?Expires=1719079179&Signature=db7q~dhBR4zd9Cy67JnXwY5R76N9vrZkwF7bHaRyU2iHU0jX-uzd9OfI8tjp9rH4C35jKRLReEXPmwyNpEgwmjan9aJlcbeEoQOXbRFTzjGmXB1yvVQvHLAf7n60af01cQTo1fOqFCj7OiCf0hyW5mUKmQP8Qq5dglHQDTQZeNFhmJyoGm4geOm4vRyfKfK3T9-Ucogb43M2rbWpklv49ErBYAuRi3OGx~BqKRIPqikltSwnsJ1D7uxyAVGh08~hoTcEdGqV-t4DmwCXvaHDd0ed0eErKTVtmymnZJP~MB6FubJWLcmfEtMp0dSHgv2qWtZuj5hinegDa-F3ekSgqQ__&Key-Pair-Id=K1U52DHN9E92VT",
      //       "type": "image/jpeg",
      //       "width": 1216,
      //       "height": 832
      //     }
      //   ]
      // };

      print('Response: $response');
      final List<String> imageUrls = (response['data'] as List<dynamic>)
          .map<String>((data) => data['asset_url'])
          .toList();
      print('Overlay image URLs: $imageUrls');
      setState(() {
        overlayImageUrls = imageUrls;
      });
    } catch (e) {
      print('Failed to generate overlay image: $e');
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
              if (overlayImageUrls != null) ...[
                SizedBox(height: 20),
                for (var url in overlayImageUrls!) Image.network(url),
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
                    if (overlayImageUrls != null &&
                        overlayImageUrls!.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(
                            camera: widget.camera,
                            frameColor: selectedFrameColor,
                            overlayImageUrls: overlayImageUrls!,
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
