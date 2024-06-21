import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  final ApiService apiService = ApiService('http://15.165.196.28');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                try {
                  final data = await apiService.fetchData('user');
                  print(data);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('User Data'),
                      content: Text(data.toString()),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  print('Error fetching user data: $e');
                }
              },
              child: Text('Fetch User Data'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraScreen()),
                );
              },
              child: Text('Go to Camera'),
            ),
          ],
        ),
      ),
    );
  }
}
