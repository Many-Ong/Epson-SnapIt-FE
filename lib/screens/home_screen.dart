import 'package:flutter/material.dart';
import 'package:snapit/screens/remove_bg_screen.dart';
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
      body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Choose Theme",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                largeButton(
                  context,
                  "assets/select_basic.png", // 첫 번째 버튼의 이미지
                  "Basic Frame", // 첫 번째 버튼의 설명
                  "You can take a picture with simple, standard frame",
                  () {
                    print("Basic Button Pressed"); // 첫 번째 버튼의 액션
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  RemoveBackGroundScreen()),
                    );
                  },
                ),
                SizedBox(height: 20), // 버튼 사이의 간격
                largeButton(
                  context,
                  "assets/select_overlay.png", // 두 번째 버튼의 이미지
                  "Your Own Overlay Frame",
                  "You can upload a person’s picture as an overlay image and take a picture with them!",
                  () {
                    print("Upload & Overlay Button Pressed"); // 두 번째 버튼의 액션
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  RemoveBackGroundScreen()),
                    );
                  },
                ),
              ],
            ),
      backgroundColor: Colors.black,
    );
  }


  Widget largeButton(BuildContext context, String imagePath, String title, String subtitle, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(10), // 패딩
        height: 150, // 컨테이너 높이 설정
        decoration: BoxDecoration(
          color: Colors.white, // 배경 색상
          boxShadow: [ // 그림자 효과
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row( // Row 위젯으로 두 개의 열 생성
          children: <Widget>[
            Expanded(
              flex: 1, // 이미지는 공간의 1/3을 차지
              child: Image.asset(imagePath, fit: BoxFit.cover), // 이미지
            ),
            Expanded(
              flex: 2, // 텍스트는 공간의 2/3을 차지
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // 제목
                  SizedBox(height: 10), // 제목과 하위 텍스트 사이 간격
                  Text(subtitle), // 하위 텍스트
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