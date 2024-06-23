import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepAiApiService {
  final String baseUrl = 'https://api.deepai.org/api';
  final String apiKey;

  DeepAiApiService() : apiKey = dotenv.env['DEEPAI_API_KEY']!;

  Future<String> text2img({
    required String text,
  }) async {
    if (apiKey == null) {
      throw Exception(
          'API key is not set. Please set the DEEPAI_API_KEY in your .env file.');
    }

    final Map<String, dynamic> requestBody = {
      'text': text,
    };

    final headers = {
      'Content-Type': 'application/json',
      'api-key': apiKey,
    };

    // Log the request details
    print('Request URL: $baseUrl/text2img');
    print('Request Headers: $headers');
    print('Request Body: $requestBody');

    final response = await http.post(
      Uri.parse('$baseUrl/text2img'),
      headers: headers,
      body: json.encode(requestBody),
    );

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      print('Failed to generate image: ${response.body}');
      throw Exception('Failed to generate image');
    }
  }
}
// // Example posting a text URL:
// (async function() {
//     const resp = await fetch('https://api.deepai.org/api/text2img', {
//         method: 'POST',
//         headers: {
//             'Content-Type': 'application/json',
//             'api-key': 'e1a3052b-80f3-4ed0-b32c-e9ab2504c38d'
//         },
//         body: JSON.stringify({
//             text: "YOUR_TEXT_URL",
//         })
//     });
    
//     const data = await resp.json();
//     console.log(data);
// })()

