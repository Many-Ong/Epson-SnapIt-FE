import 'dart:io';
import 'package:image/image.dart' as img;

Future<img.Image> cropImage(File imageFile, double aspectRatio) async {
  // 이미지 파일을 로드
  List<int> imageBytes = await imageFile.readAsBytes();
  img.Image originalImage = img.decodeImage(imageBytes)!;

  // 이미지 크기와 비율 계산
  int originalWidth = originalImage.width;
  int originalHeight = originalImage.height;
  int targetWidth, targetHeight;

  // 비율에 맞게 타겟 크기 설정
  if (originalWidth / originalHeight > aspectRatio) {
    targetHeight = originalHeight;
    targetWidth = (originalHeight * aspectRatio).round();
  } else {
    targetWidth = originalWidth;
    targetHeight = (originalWidth / aspectRatio).round();
  }

  // 중앙에서 이미지 크롭
  int offsetX = (originalWidth - targetWidth) ~/ 2;
  int offsetY = (originalHeight - targetHeight) ~/ 2;
  img.Image croppedImage = img.copyCrop(originalImage, offsetX, offsetY, targetWidth, targetHeight);

  // 필요한 경우 이미지 크기 조정
  return croppedImage;
}
