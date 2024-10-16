import 'package:flutter/material.dart';
import 'package:snapit/screens/remove_bg_screen.dart';
import 'package:snapit/screens/camera_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  final bool camerasAvailable;
  final ApiService apiService = ApiService('http://15.165.196.28');

  HomeScreen({super.key, required this.camerasAvailable});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child:
            camerasAvailable ? _buildContent(context) : _buildNoCameraMessage(),
      ),
    );
  }

  @override
  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Image.asset(
            'assets/logo.png',
            height: 40,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView to enable scrolling
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              largeButton(
                context,
                "assets/select_unm_frame.png",
                "UNM Special Frame",
                "You can take 4-cut photos with UNM special frame",
                Color.fromARGB(255, 186, 12, 47),
                Color.fromARGB(150, 255, 255, 255),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        overlayImages: [],
                        isBasicFrame: true,
                        isSpecialFrame: true,
                        grid: '2x2',
                        specialFrame: 'UNM',
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              largeButton(
                context,
                "assets/select_klcc_halloween_frame.png",
                "KLCC Holloween Special Frame",
                "You can take 4-cut photos with KLCC Halloween special frame",
                Color.fromARGB(255, 5, 45, 102),
                Color.fromARGB(100, 255, 255, 255),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        overlayImages: [],
                        isBasicFrame: true,
                        isSpecialFrame: true,
                        grid: '2x2',
                        specialFrame: 'klcc',
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              largeButton(
                context,
                "assets/select_special.png",
                "Football Special Frame",
                "You can take 4-cut photos with special frame",
                Color.fromARGB(255, 46, 184, 49),
                Colors.white,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        overlayImages: [],
                        isBasicFrame: true,
                        isSpecialFrame: true,
                        grid: '2x2',
                        specialFrame: 'football',
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              largeButton(
                context,
                "assets/select_basic.png",
                "4-cut 4x1",
                "You can take 4-cut photos with simple, standard frame",
                Colors.black,
                Colors.white,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        overlayImages: [],
                        isBasicFrame: true,
                        isSpecialFrame: false,
                        grid: '4x1',
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              largeButton(
                context,
                "assets/select_2x2.png",
                "4-cut 2x2",
                "You can take 4-cut photos with 2x2 grid frame",
                Colors.black,
                Colors.white,
                () {
                  print("Basic Button Pressed");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        overlayImages: [],
                        isBasicFrame: true,
                        isSpecialFrame: false,
                        grid: '2x2',
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget largeButton(
      BuildContext context,
      String imagePath,
      String title,
      String subtitle,
      Color backgroundColor,
      Color imageBackgroundColor,
      VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(10), // Padding
        width: 348,
        height: 200, // Container height
        decoration: BoxDecoration(
          color: backgroundColor, // Background color
          borderRadius: BorderRadius.circular(12), // Rounded corners
          border:
              Border.all(color: Color(0xFF1F1F1F), width: 1), // Border color
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              width: 130,
              height: 189,
              decoration: BoxDecoration(
                color: imageBackgroundColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Image.asset(
                    width: 100,
                    height: 179,
                    imagePath,
                    fit: BoxFit.contain), // Image
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Center(
                      child: Text(
                        title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ), // Title
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 10), // Padding
                    child: Center(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ), // Subtitle
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCameraMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.camera_alt, size: 100, color: Colors.grey),
        SizedBox(height: 20),
        Text(
          'No cameras available',
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      ],
    );
  }
}
