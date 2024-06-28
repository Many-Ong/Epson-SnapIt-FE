import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepAiApiService {
  final String baseUrl = 'https://api.deepai.org/api';
  final String apiKey;

  DeepAiApiService() : apiKey = dotenv.env['DEEPAI_API_KEY']!;

  Future<String> text2img({required String text}) async {
    if (apiKey == null) {
      throw Exception(
          'API key is not set. Please set the DEEPAI_API_KEY in your .env file.');
    }

    final Map<String, dynamic> requestBody = {'text': text};
    final headers = {
      'Content-Type': 'application/json',
      'api-key': apiKey,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/text2img'),
      headers: headers,
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      throw Exception('Failed to generate image: ${response.body}');
    }
  }

  Future<String> aiSelfieGenerator({
    required File imageFile,
    required String text,
  }) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/ai-selfie-generator'))
      ..headers['api-key'] = apiKey
      ..fields['text'] = text
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseData.body;
    } else {
      throw Exception('Failed to generate AI selfie: ${responseData.body}');
    }
  }

  Future<String> removeBackground(String imageUrl) async {
    final Map<String, dynamic> requestBody = {
      'image': imageUrl,
    };

    print('Removing background from image: $imageUrl');
    print('Request body: $requestBody');

    final headers = {
      'Content-Type': 'application/json',
      'api-key': apiKey,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/background-remover'),
      headers: headers,
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Background removed successfully: ${response.body}');
      return response.body;
    } else {
      throw Exception('Failed to remove background: ${response.body}');
    }
  }
}
