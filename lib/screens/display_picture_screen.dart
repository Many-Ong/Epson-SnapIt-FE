import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:snapit/screens/print_screen.dart';

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  DisplayPictureScreen({required this.imagePath, required BuildContext context});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: SafeArea(
        child: Center(
          child: Container(
            color: Colors.black,
            child:Image.file(
                File(imagePath),
                fit: BoxFit.cover, // Ensure the image fits within the bounds without distortion
              ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PrintScreen(imagePath: imagePath),
            ),
          );
        },
        child: Icon(Icons.print, color: Colors.black),
      ),
    );
  }
}
