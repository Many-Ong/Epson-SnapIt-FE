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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "Choose Theme",
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          largeButton(
            context,
            "assets/select_basic.png",
            "Basic Frame",
            "You can take a picture with simple, standard frame",
            () {
              print("Basic Button Pressed");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraScreen(
                    overlayImages: [],
                    isBasicFrame: true,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          largeButton(
            context,
            "assets/select_overlay.png",
            "Your Own Overlay Frame",
            "You can upload a person’s picture as an overlay image and take a picture with them!",
            () {
              print("Upload & Overlay Button Pressed");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RemoveBackGroundScreen(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget largeButton(BuildContext context, String imagePath, String title,
      String subtitle, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(10),
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text(subtitle),
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
