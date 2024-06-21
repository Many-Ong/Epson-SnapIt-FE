import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PrintScreen extends StatelessWidget {
  final String imagePath;
  final ApiService apiService = ApiService('http://15.165.196.28');

  PrintScreen({required this.imagePath});

  Future<void> handlePrint() async {
    try {
      // Step 1: Authenticate
      final authResponse = await apiService.authenticate('');
      final accessToken = authResponse['access_token'];
      final subjectId = authResponse['subject_id'];

      // Step 2: Set Print Settings
      final printSettingResponse = await apiService.printSetting(
        accessToken,
        subjectId,
        'SampleJob1',
        'photo',
      );
      final jobId = printSettingResponse['id'];
      final uploadUri = printSettingResponse['upload_uri'];

      // Step 3: Upload Print File
      await apiService.uploadPrintFile(uploadUri, imagePath);

      // Step 4: Execute Print
      final executePrintResponse = await apiService.executePrint(
        accessToken,
        subjectId,
        jobId,
      );

      print('Print executed successfully: $executePrintResponse');
    } catch (e) {
      print('Error during print process: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Print Picture')),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 40),
            Flexible(
              flex: 3,
              child: Center(
                child: Image.file(File(imagePath), fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 40),
            SizedBox(
              width: 160,
              height: 46,
              child: ElevatedButton(
                onPressed: () async {
                  await handlePrint();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, // Set the background color
                  backgroundColor: Colors.white, // Set the text color
                ),
                child: Text('Print Picture!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
