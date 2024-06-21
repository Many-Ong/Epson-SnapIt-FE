import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:snapit/screens/print_screen.dart';

Widget DisplayPictureScreen({required String imagePath, required BuildContext context}) { // 사진을 보여주는 화면
  return Scaffold(
    appBar: AppBar(title: const Text('Display the Picture')),
    body: Image.file(File(imagePath)),
    floatingActionButton: Builder(
      builder: (BuildContext context) {
        return FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PrintScreen(imagePath: imagePath)),
            );
          },
          child: Icon(Icons.print),
        );
      },
    ),
  );
}