import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snapit/screens/home_screen.dart';
import 'package:social_share/social_share.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DisplayPictureScreen extends StatefulWidget {
  final img.Image mergedFourImage;
  final bool isSpecialFrame;
  final String appId;

  DisplayPictureScreen({
    super.key,
    required this.mergedFourImage,
    required this.isSpecialFrame,
    required BuildContext context,
  }) : appId = dotenv.env['APP_ID']!;

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  Color selectedFrameColor = const Color.fromARGB(255, 255, 255, 255);
  late Uint8List originalImageBytes; // Store the original image bytes
  bool isLoading = false;
  img.Image frame = img.Image(0, 0);

  @override
  void initState() {
    super.initState();
    // Initialize the original image bytes
    originalImageBytes =
        Uint8List.fromList(img.encodePng(widget.mergedFourImage));
    loadFrameImage();
  }

  Future<void> loadFrameImage() async {
    ByteData frameData = await rootBundle.load('assets/frame.png');
    frame = img.decodeImage(frameData.buffer.asUint8List())!;
  }

  Future<String> createImageFile(Uint8List imageBytes) async {
    // Create the framed image with the selected frame color
    // final framedImage =
    //     applyFrameColor(widget.mergedFourImage, selectedFrameColor);

    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/temp_image.png').create();
    await tempFile.writeAsBytes(img.encodePng(widget.mergedFourImage));
    return tempFile.path;
  }

  // Function to apply frame color to the image
  img.Image applyFrameColor(img.Image baseImage, Color frameColor) {
    // Create a new image with padding for the frame
    // final int gap = 62; // Set frame width
    // final int margin = 81;
    final img.Image framedImage = img.Image(
      baseImage.width,
      baseImage.height,
    );

    // Fill the frame area with the selected color
    img.fill(framedImage,
        img.getColor(frameColor.red, frameColor.green, frameColor.blue));

    img.copyInto(framedImage, baseImage, dstX: 0, dstY: 0);

    return framedImage;
  }

  Future<void> saveImageToGallery() async {
    String imageFilePath = await createImageFile(originalImageBytes);

    final result = await Permission.storage.request();
    if (result.isGranted) {
      final File imageFile = File(imageFilePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(imageBytes);
      print('Image saved to gallery: $result');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Image Saved', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          margin:
              const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      print('Permission denied');
    }
  }

  bool _isDialogShowing = false; // 다이얼로그 중복 방지 플래그

  void showLoadingIndicator(BuildContext context) {
    if (!_isDialogShowing) {
      _isDialogShowing = true; // 다이얼로그가 이미 표시 중인지 플래그로 체크
      showDialog(
        context: context,
        barrierDismissible: false, // 사용자가 뒤를 클릭해도 닫히지 않도록 설정
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
      );
    }
  }

  void hideLoadingIndicator(BuildContext context) {
    if (_isDialogShowing && mounted) {
      _isDialogShowing = false; // 다이얼로그 표시 상태 해제
      Navigator.of(context, rootNavigator: true).pop(); // 다이얼로그 닫기
    }
  }

  Future<void> saveImageToFirebaseStorage(BuildContext context) async {
    String imageFilePath = await createImageFile(originalImageBytes);
    String? downloadUrl;
    try {
      showLoadingIndicator(context); // 로딩 인디케이터 표시

      // 비동기 파일 읽기
      final File imageFile = File(imageFilePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Firebase Storage 참조 및 파일 업로드
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child("4cuts/${DateTime.now().millisecondsSinceEpoch}.png");

      // 메타데이터 설정
      final metadata = SettableMetadata(contentType: 'image/png');
      await imageRef.putData(imageBytes, metadata);

      // 다운로드 URL 가져오기
      downloadUrl = await imageRef.getDownloadURL();
      print('Image saved to Firebase Storage: $downloadUrl');

      // QR 코드 모달 표시 (업로드 성공 시에만)
      if (downloadUrl != null) {
        hideLoadingIndicator(context);
        _showQRCodeModal(context, downloadUrl);
      }
    } catch (e) {
      print('Error saving image to Firebase Storage: $e');
    } finally {
      hideLoadingIndicator(context); // 항상 로딩 인디케이터를 숨김
    }
  }

  void _showQRCodeModal(BuildContext context, String downloadUrl) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true, // 창 밖을 눌렀을 때 모달을 닫을 수 있도록 설정
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Download Image with QR Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              SizedBox(
                // 명시적으로 크기를 설정
                width: 150,
                height: 150,
                child: QrImageView(
                  data: downloadUrl, // QR 코드에 다운로드 링크 삽입
                  version: QrVersions.auto,
                  gapless: false,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // 모달 닫기
              },
              textStyle: const TextStyle(color: Colors.blue),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkAndShareImageToInstagramStory() async {
    const instagramUrl = 'instagram://app';
    if (await canLaunchUrlString(instagramUrl)) {
      await shareImageToInstagramStory();
    } else {
      print('Instagram not installed');
      showInstallInstagramDialog();
    }
  }

  void showInstallInstagramDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Instagram Not Installed'),
          content: const Text('Install Instagram to share your story?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Install'),
              onPressed: () {
                launch('https://apps.apple.com/us/app/instagram/id389801252');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> shareImageToInstagramStory() async {
    String imageFilePath = await createImageFile(originalImageBytes);

    await SocialShare.shareInstagramStory(
      appId: widget.appId,
      imagePath: imageFilePath,
      backgroundTopColor: "#ffffff",
      backgroundBottomColor: "#000000",
    );
  }

  Future<void> shareImage() async {
    String imageFilePath = await createImageFile(originalImageBytes);

    File imageFile = File(imageFilePath);
    final Uint8List imageBytes = imageFile.readAsBytesSync();

    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/temp_image.jpg').create();
    await tempFile.writeAsBytes(imageBytes);

    final XFile xFile = XFile(tempFile.path);

    Share.shareXFiles([xFile],
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        subject: widget.appId,
        text: 'SnapIT!');
  }

  Future<bool> _onWillPop() async {
    return (await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Do you want to exit?'),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                textStyle: const TextStyle(color: Colors.blue),
                child: const Text('No'),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(true),
                textStyle: const TextStyle(color: Colors.blue),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> frameColors = [
      const Color.fromARGB(255, 186, 12, 47),
      const Color.fromARGB(255, 255, 200, 221),
      const Color.fromARGB(255, 255, 175, 204),
      const Color.fromARGB(255, 255, 173, 173),
      const Color.fromARGB(255, 255, 214, 165),
      const Color.fromARGB(255, 253, 255, 182),
      const Color.fromARGB(255, 202, 255, 191),
      const Color.fromARGB(255, 189, 224, 254),
      const Color.fromARGB(255, 162, 210, 255),
      const Color.fromARGB(255, 160, 196, 255),
      const Color.fromARGB(255, 189, 178, 255),
      const Color.fromARGB(255, 205, 180, 219),
      const Color.fromARGB(255, 192, 192, 192),
      Colors.white,
    ];

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () async {
              bool exit = await _onWillPop();
              if (exit) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => HomeScreen(
                            camerasAvailable: true,
                          )),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40),
            Flexible(
              flex: 3,
              child: Center(
                child: isLoading
                    ? const Text('Loading...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Roboto'))
                    : Container(
                        padding:
                            const EdgeInsets.all(2), // Padding for the frame
                        color: selectedFrameColor, // Frame color
                        child: Image.memory(
                          originalImageBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            if (!widget.isSpecialFrame)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
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
                                ? Colors.grey[900]!
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: saveImageToGallery,
              child: const Icon(
                Icons.download,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: checkAndShareImageToInstagramStory,
              child: Image.asset(
                'assets/instagram_icon_bw.png',
                width: 28,
                height: 28,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: shareImage,
              child: const Icon(
                Icons.share,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: () async {
                await saveImageToFirebaseStorage(context); // 비동기 함수를 호출
              },
              child: const Icon(
                Icons.qr_code,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
