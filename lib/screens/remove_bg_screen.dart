import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snapit/screens/camera_screen.dart';
import 'dart:math';
import 'package:local_rembg/local_rembg.dart';
import '../utils/image_picker_util.dart';
import 'package:flutter/cupertino.dart';

class RemoveBackGroundScreen extends StatefulWidget {
  RemoveBackGroundScreen();

  @override
  _RemoveBackGroundScreenState createState() => _RemoveBackGroundScreenState();
}

class _RemoveBackGroundScreenState extends State<RemoveBackGroundScreen> {
  List<File> uploadedImages = [];
  List<String> processedImageUrls = [];
  TextEditingController _textController = TextEditingController();
  bool isLoading = false;
  bool isUploading = false;
  Uint8List? imageBytes;
  String? message;

  Future<void> _pickImages() async {
    setState(() {
      isUploading = true;
    });

    uploadedImages =
        await ImagePickerUtil.pickImages(context, uploadedImages, 4);

    setState(() {
      isUploading = false;
    });
  }

  Future<String> _saveImageToFileSystem(Uint8List imageBytes) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String fileName = "processed_${DateTime.now().millisecondsSinceEpoch}.png";
    File file = File('${directory.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  Future<void> _processImages() async {
    setState(() {
      isLoading = true;
    });

    List<String> processedImageUrls = [];

    for (var imageFile in uploadedImages) {
      try {
        LocalRembgResultModel localRembgResultModel =
            await LocalRembg.removeBackground(imagePath: imageFile.path);
        if (localRembgResultModel.status == 1) {
          Uint8List imageBytes =
              Uint8List.fromList(localRembgResultModel.imageBytes!);
          String imageUrl = await _saveImageToFileSystem(imageBytes);
          processedImageUrls.add(imageUrl);
        } else {
          // 배경 제거 실패 시
          throw Exception(
              'Background removal failed: ${localRembgResultModel.errorMessage}');
        }
      } catch (e) {
        print('Error processing image: $e');
        // Show alert and clear uploaded images
        _showAlertAndChooseWays();
      }
    }

    setState(() {
      isLoading = false;
    });

    if (processedImageUrls.isEmpty) {
      _showAlertAndClearImages();
      return;
    } else if (processedImageUrls.length < 4) {
      useSuccessfulPhotos();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
            overlayImages: processedImageUrls, isBasicFrame: false),
      ),
    );
  }

  void useSuccessfulPhotos() {
    // 성공한 사진만 반복해서 사용하도록 처리
    var randomIndex = 0;
    while (processedImageUrls.length < 4) {
      randomIndex = Random().nextInt(processedImageUrls.length);
      processedImageUrls.add(processedImageUrls[randomIndex]);
    }
  }

  void _showAlertAndClearImages() {
    // 모든 이미지에서 배경 제거 실패 시
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Background removal failed for all photos'),
          content: Text(
              'Please try again with different photos.'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                // 사용자가 다시 업로드할 수 있도록 처리
                setState(() {
                  isLoading = false;
                  uploadedImages.clear();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAlertAndChooseWays() {
    // 한 이미지에서 배경 제거 실패 시
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Background removal failed'),
          content: Text(
              'This process failed for the nth photo.\nPlease choose an option below.'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Use Successful Photos',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                // 현재 다이얼로그를 닫고 이전 과정을 이어서 실행
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Re-upload All Photos',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                // 사용자가 전체 사진을 재업로드할 수 있도록 처리
                setState(() {
                  isLoading = false;
                  uploadedImages.clear();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: uploadedImages.length < 4 ? _pickImages : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text(
                'Upload Images',
                selectionColor: Colors.black,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Select 4 portrait images to remove background. \nOnly portrait images are supported.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 52),
            Text(
              '${uploadedImages.length}/4 selected',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 16),
            Expanded(
              child: isUploading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2),
                      itemCount: uploadedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Image.file(uploadedImages[index]),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    uploadedImages.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            if (isLoading)
              CircularProgressIndicator(
                color: Colors.white,
              )
            else
              ElevatedButton(
                onPressed: uploadedImages.length == 4 && !isLoading
                    ? () async {
                        await _processImages();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(28), // Reduced border radius
                  ),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
