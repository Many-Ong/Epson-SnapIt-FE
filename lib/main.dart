import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:snapit/screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Could not load .env file: $e');
  }

  final cameras = await availableCameras();
  bool camerasAvailable = cameras.isNotEmpty;

  print('Cameras available: $camerasAvailable');

  runApp(MyApp(camerasAvailable: camerasAvailable));
}

class MyApp extends StatelessWidget {
  final bool camerasAvailable;

  const MyApp({super.key, required this.camerasAvailable});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        //기존 속성 유지하며 폰트만 추가
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Pretendard',
            ),
      ),
      home: HomeScreen(
        camerasAvailable: camerasAvailable,
      ), // Set HomeScreen as the home screen
    );
  }
}
