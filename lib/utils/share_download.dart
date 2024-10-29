import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_share/social_share.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<void> saveImageToGallery(BuildContext context, String imageFilePath) async {
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
  if (_isDialogShowing) {
    _isDialogShowing = false; // 다이얼로그 표시 상태 해제
    Navigator.of(context, rootNavigator: true).pop(); // 다이얼로그 닫기
  }
}

Future<void> saveImageToFirebaseStorage(BuildContext context, String imageFilePath) async {
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

Future<void> checkAndShareImageToInstagramStory(String imageFilePath, String appId, BuildContext context) async {
  const instagramUrl = 'instagram://app';
  if (await canLaunchUrlString(instagramUrl)) {
    await shareImageToInstagramStory(imageFilePath, appId);
  } else {
    print('Instagram not installed');
    showInstallInstagramDialog(context);
  }
}

void showInstallInstagramDialog(BuildContext context) {
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

Future<void> shareImageToInstagramStory(String imageFilePath, String appId) async {
  await SocialShare.shareInstagramStory(
    appId: appId,
    imagePath: imageFilePath,
    backgroundTopColor: "#ffffff",
    backgroundBottomColor: "#000000",
  );
}

Future<void> shareImage(String imageFilePath, String appId) async {
  File imageFile = File(imageFilePath);
  final Uint8List imageBytes = imageFile.readAsBytesSync();

  final tempDir = await getTemporaryDirectory();
  final tempFile = await File('${tempDir.path}/temp_image.jpg').create();
  await tempFile.writeAsBytes(imageBytes);

  final XFile xFile = XFile(tempFile.path);

  Share.shareXFiles([xFile],
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      subject: appId,
      text: 'SnapIT!');
}

Future<bool> onWillPop(BuildContext context) async {
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