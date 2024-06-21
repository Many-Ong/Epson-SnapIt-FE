import 'dart:io';
import 'package:flutter/material.dart';

Widget DisplayPictureScreen({required String imagePath}) { // 사진을 보여주는 화면
  return Scaffold(
    appBar: AppBar(title: const Text('Display the Picture')),
    body: Image.file(File(imagePath)),
  );
}