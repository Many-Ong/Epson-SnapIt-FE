import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import 'ai_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  final CameraDescription? camera;
  final bool camerasAvailable;
  final ApiService apiService = ApiService('http://15.165.196.28');

  HomeScreen({super.key, required this.camera, required this.camerasAvailable});

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

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Spacer(),
        Image.asset('assets/logo.png', width: 300), // Display the logo image
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AISelectionScreen(camera: camera!)),
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
              'START',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
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
