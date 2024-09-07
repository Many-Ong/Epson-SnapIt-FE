import 'package:flutter/material.dart';
import 'package:snapit/screens/remove_bg_screen.dart';
import 'package:snapit/screens/camera_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  final bool camerasAvailable;
  final ApiService apiService = ApiService('http://15.165.196.28');

  HomeScreen({super.key, required this.camerasAvailable});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child:
            camerasAvailable ? _buildContent(context) : _buildNoCameraMessage(),
      ),
    );
  }

  @override
  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Image.asset(
            'assets/logo.png',
            height: 40,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 70),
            largeButton(
              context,
              "assets/select_basic.png",
              "4-cut 4x1",
              "You can take 4-cut photos with simple, standard frame",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      overlayImages: [],
                      isBasicFrame: true,
                      grid: '4x1',
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 40),
            largeButton(
              context,
              "assets/select_2x2.png",
              "4-cut 2x2",
              "You can take 4-cut photos with 2x2 grid frame",
              () {
                print("Basic Button Pressed"); // 첫 번째 버튼의 액션
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      overlayImages: [],
                      isBasicFrame: true,
                      grid: '2x2',
                    ),
                  ),
                );
              },
            ), // 버튼 사이의 간격
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget largeButton(BuildContext context, String imagePath, String title,
      String subtitle, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(10), // 패딩
        width: 348,
        height: 220, // 컨테이너 높이 설정
        decoration: BoxDecoration(
          color: Colors.black, // 배경 색상
          borderRadius: BorderRadius.circular(12), // 컨테이너 모서리 둥글게
          border: Border.all(color: Color(0xFF1F1F1F), width: 1), // 테두리 색상
        ),
        child: Row(
          // Row 위젯으로 두 개의 열 생성
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              width: 130,
              height: 189,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Image.asset(
                    width: 100,
                    height: 179,
                    imagePath,
                    fit: BoxFit.contain), // 이미지
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Center(
                      child: Text(
                        title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ), // 제목
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 10), // 패딩을 주변에 적용
                    child: Center(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Colors.white),
                      ),
                    ), // 하위 텍스트
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCameraMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.camera_alt, size: 100, color: Colors.grey),
        SizedBox(height: 20),
        Text(
          'No cameras available',
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      ],
    );
  }
}
