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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.file(File(imagePath)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await handlePrint();
            },
            child: Text('Print Picture'),
          ),
        ],
      ),
    );
  }
}