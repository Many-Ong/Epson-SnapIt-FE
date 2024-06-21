import 'dart:io';

import 'package:flutter/material.dart' hide Image; // flutter.Image와 충돌을 피하기 위해 hide Image 사용
import 'package:flutter/material.dart' as flutter;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:snapit/screens/display_picture_screen.dart';
import 'package:snapit/assets.dart';
import 'print_screen.dart';

class CameraScreen extends StatefulWidget { 
  final CameraDescription camera; //

  const CameraScreen({super.key, required this.camera});
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
                Center(
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: CameraPreview(_controller!),
                  ),
                ),
                Center(
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: flutter.Image.asset(
                      Assets.overlayImage1,
                      fit: BoxFit.contain, // Maintain the aspect ratio of the overlay image
                    ),
                  ),
                ),
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
            String mergedImagePath = await mergeImage(image, Assets.overlayImage1);

            if (!mounted) return;

            if (mergedImagePath.isNotEmpty) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(imagePath: mergedImagePath, context: context),
                ),
              );
            } else {
              print('이미지 합성에 실패하여 파일이 저장되지 않았습니다.');
            }
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Future<String> mergeImage(XFile picture, String overlayAsset) async {
    File file = File(picture.path);

    if (!file.existsSync()) {
      print('파일이 존재하지 않습니다');
      return '';
    }

    img.Image baseImage = img.decodeImage(file.readAsBytesSync())!;
    img.Image flippedImage = img.flipHorizontal(baseImage); // 이미지를 수평으로 뒤집음

    // Get the dimensions of the base image
    int baseWidth = baseImage.width;
    int baseHeight = baseImage.height;

    // Load the overlay image
    ByteData data = await rootBundle.load(overlayAsset);
    Uint8List bytes = data.buffer.asUint8List();
    img.Image overlayImage = img.decodeImage(bytes)!;

    // Resize the flipped image to match the aspect ratio of 4:3
    img.Image resizedFlippedImage = img.copyResize(
      flippedImage,
      width: 4 * baseHeight ~/ 3,
      height: baseHeight,
    );

    // Resize the overlay image to match the aspect ratio of the flipped image
    img.Image resizedOverlayImage = img.copyResize(
      overlayImage,
      width: resizedFlippedImage.width,
      height: (resizedFlippedImage.width * overlayImage.height / overlayImage.width).round(),
    );

    // Center the resized overlay image on the flipped image
    int offsetX = (resizedFlippedImage.width - resizedOverlayImage.width) ~/ 2;
    int offsetY = (resizedFlippedImage.height - resizedOverlayImage.height) ~/ 2;
    img.copyInto(resizedFlippedImage, resizedOverlayImage, dstX: offsetX, dstY: offsetY);

    // Save the merged image
    String newPath = '${file.parent.path}/merged_${DateTime.now()}.png';
    File newImageFile = File(newPath)..writeAsBytesSync(img.encodePng(resizedFlippedImage));
    print('새로운 이미지가 저장되었습니다: $newPath');
    return newImageFile.path;
  }

  Widget _buildOverlay() {
    return flutter.Image.asset(Assets.overlayImage1);
  }
}
