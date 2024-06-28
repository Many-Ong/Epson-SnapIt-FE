import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:snapit/screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Could not load .env file: $e');
  }

  final cameras = await availableCameras();
  bool camerasAvailable = cameras.isNotEmpty;

  print('Cameras available: $camerasAvailable');

  final firstCamera = camerasAvailable ? cameras.first : null;

  runApp(MyApp(camera: firstCamera, camerasAvailable: camerasAvailable));
}

class MyApp extends StatelessWidget {
  final CameraDescription? camera;
  final bool camerasAvailable;

  const MyApp(
      {super.key, required this.camera, required this.camerasAvailable});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith( //기존 속성 유지하며 폰트만 추가
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'AvenirNext',
            ),
      ),
      home: HomeScreen(
        camera: camera,
        camerasAvailable: camerasAvailable,
      ), // Set HomeScreen as the home screen
    );
  }
}
