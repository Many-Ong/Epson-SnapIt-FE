import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras(); 
  final firstCamera = cameras.first; 

  runApp(MyApp(camera: firstCamera)); 
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({required this.camera});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: CameraScreen(camera: camera), 
    );
  }
}

class CameraScreen extends StatefulWidget { 
  final CameraDescription camera;

  const CameraScreen({required this.camera});
  @override
  _CameraScreenState createState() => _CameraScreenState();
} //확인

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller; 
  late Future<void> _initializeControllerFuture;
  List<CameraDescription> cameras = [];

  @override
  void initState() { // 초기화 작업
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras(); 
    CameraDescription frontCamera = cameras.firstWhere( // 전면 카메라를 찾음
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    ); // 전면 카메라 없으면 후면 카메라 사용
    _controller = CameraController(frontCamera, 
    ResolutionPreset.medium); // 카메라 컨트롤러를 초기화
    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {}); // UI 업데이트
    }). catchError((error) {
      print('카메라 초기화 중에 에러가 발생했습니다: $error');
    }); // 

    await _controller!.initialize();

    if (!mounted) return;
    setState(() {}); // UI 상태 업데이트
  }

  @override
  void dispose() { // 카메라 사용이 끝나면 controller를 dispose해야 함 
    _controller?.dispose(); 
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Camera')),
      body: FutureBuilder<void>( // FutureBuilder는 Future의 결과에 따라 UI를 업데이트
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: <Widget>[
                CameraPreview(_controller!),
                _buildOverlay(),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller!.takePicture();
            if (!mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: image.path),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
        child: Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildOverlay() {
    return Align(
      alignment: Alignment.center,
      child: Image.asset('assets/camera_test.png'), // 카메라 위에 겹쳐질 이미지
    );
  }
}

Widget DisplayPictureScreen({required String imagePath}) { // 사진을 보여주는 화면
  return Scaffold(
    appBar: AppBar(title: Text('Display the Picture')),
    body: Image.file(File(imagePath)),
  );
}



