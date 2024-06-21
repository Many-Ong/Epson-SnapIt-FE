import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'camera_screen.dart';
import 'package:camera/camera.dart';

class HomeScreen extends StatelessWidget {
  final CameraDescription camera;
  final ApiService apiService = ApiService('http://15.165.196.28');

  HomeScreen({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                try {
                  final data = await apiService.fetchData('user');
                  print(data);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('User Data'),
                      content: Text(data.toString()),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  print('Error fetching user data: $e');
                }
              },
              child: const Text('Fetch User Data'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraScreen(camera: camera)),
                );
              },
              child: const Text('Go to Camera'),
            ),
          ],
        ),
      ),
    );
  }
}
