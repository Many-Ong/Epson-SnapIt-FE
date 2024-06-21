import 'dart:io';

import 'package:flutter/material.dart' hide Image; // flutter.Image와 충돌을 피하기 위해 hide Image 사용
import 'package:flutter/material.dart' as flutter;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:snapit/screens/display_picture_screen.dart';
import 'package:snapit/assets.dart';
import 'package:path_provider/path_provider.dart';

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
  int pictureCount = 0; //촬영된 사진의 수
  List<String> takePictures = []; //촬영된 사진 경로 목록

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
    _initializeControllerFuture = _controller!.initialize().then((_) async {
      if (!mounted) return;
      // 카메라 초기화가 완료되면 플래시 모드를 off로 설정
      await _controller!.setFlashMode(FlashMode.off);

      setState(() {}); // UI 업데이트
    }). catchError((error) {
      print('카메라 초기화 중에 에러가 발생했습니다: $error');
    }); // 
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
                      Assets.overlayImages[pictureCount],
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
            if (pictureCount < 4) {
              await _initializeControllerFuture;
              final XFile image = await _controller!.takePicture();
              String overlayImagePath = await mergeImage(image, Assets.overlayImages[pictureCount]);
              takePictures.add(overlayImagePath); // 이미지 경로를 목록에 추가
              pictureCount++; // 촬영된 사진 수 증가

              // 4장의 이미지가 모두 촬영되면 이미지 합성
              if (pictureCount == 4) {
                String mergedImagePath = await mergeFourImages(takePictures);
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DisplayPictureScreen(imagePath: mergedImagePath, context: context),
                  ),
                );
                pictureCount = 0; // 촬영된 사진 수 초기화
                takePictures.clear(); // 촬영된 사진 경로 목록 초기화
              }
            }
            // await _initializeControllerFuture;
            // final image = await _controller!.takePicture();
            // String imagePath = image.path;
            // takePictures.add(imagePath); // 이미지 경로를 목록에 추가
            // String mergedImagePath = await mergeImage(image, Assets.overlayImages[pictureCount]); 
            // pictureCount++; // 촬영된 사진 수 증가

            // if (!mounted) return;

            // if (merge) { 
            //   String mergedFourImagePath = await mergeFourImages(takePictures);

            //   if (pictureCount == 4){
            //     await Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) => DisplayPictureScreen(imagePath: mergedImagePath, context: context),
            //       ),
            //     );
            //     pictureCount = 0; //촬영된 사진 수 초기화
            //     takePictures = []; //촬영된 사진 경로 목록 초기화
            //   }
            // } else {
            //   print('이미지 합성에 실패하여 파일이 저장되지 않았습니다.');
            // }
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

  Future<String> mergeFourImages(List<String> imagePaths) async{
    List<img.Image> images = [];

    // 이미지 경로에서 이미지를 읽어들임
    for (String path in imagePaths) {
      img.Image image = img.decodeImage(File(path).readAsBytesSync())!;
      images.add(image);
    }
    // 합설할 이미지의 너비와 높이 계산
    int width = images[0].width;
    int height = images.fold(0, (prev, element) => prev + element.height);

    // 합성된 이미지를 저장할 새 이미지 생성
    img.Image mergedFourImage = img.Image(width, height);

    // 각 이미지를 적절한 위치에 복사
    int offsetY = 0;
    for (img.Image image in images) {
      img.copyInto(mergedFourImage, image, dstY: offsetY);
      offsetY += image.height;
    }

    // 합성된 이미지를 저장 후 리턴
    Directory dic = await getApplicationDocumentsDirectory();
    String filename = '${dic.path}/merged_${DateTime.now()}.png';
    File(filename).writeAsBytesSync(img.encodePng(mergedFourImage));
    return filename;
  }
}
