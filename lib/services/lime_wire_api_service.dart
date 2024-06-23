import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LimeWireApiService {
  final String baseUrl = 'https://api.limewire.com/api';
  final String apiKey;

  LimeWireApiService() : apiKey = dotenv.env['LIME_WIRE_API_KEY']!;

  Future<Map<String, dynamic>> generateImage({
    required String prompt,
    required String aspectRatio,
    String? negativePrompt,
    int? samples,
    String? quality,
    int? guidanceScale,
    String? style,
    String apiVersion = 'v1', // Default API version
    String accept = 'application/json', // Default Accept header
  }) async {
    final Map<String, dynamic> requestBody = {
      'prompt': prompt,
      'aspect_ratio': aspectRatio,
      if (negativePrompt != null) 'negative_prompt': negativePrompt,
      if (samples != null) 'samples': samples,
      if (quality != null) 'quality': quality,
      if (guidanceScale != null) 'guidance_scale': guidanceScale,
      if (style != null) 'style': style,
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'X-Api-Version': apiVersion,
      'Accept': accept,
    };

    // Log the request details
    print('Request URL: $baseUrl/image/generation');
    print('Request Headers: $headers');
    print('Request Body: ${json.encode(requestBody)}');

    final response = await http.post(
      Uri.parse('$baseUrl/image/generation'),
      headers: headers,
      body: json.encode(requestBody),
    );

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      print('Failed to generate image: ${response.body}');
      throw Exception('Failed to generate image');
    }
  }
}
