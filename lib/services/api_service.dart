import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<Map<String, dynamic>> fetchData(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl/$endpoint'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, dynamic>> postData(
      String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to post data');
    }
  }

  Future<Map<String, dynamic>> authenticate(String refreshToken) async {
    print('Authenticating... refreshToken: $refreshToken');

    final response = await http.post(
      Uri.parse('$baseUrl/epson/authenticate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
    );

    print('Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = json.decode(response.body);
      print('Authenticated successfully: responseBody $responseBody');
      final responseData = responseBody['data'];
      print('Authenticated successfully: responseData $responseData');
      return responseData;
    } else {
      throw Exception('Failed to authenticate');
    }
  }

  Future<Map<String, dynamic>> printSetting(
    String accessToken,
    String subjectId,
    String jobName,
    String printMode,
  ) async {
    final uri =
        Uri.parse('$baseUrl/epson/print-setting').replace(queryParameters: {
      'access-token': accessToken,
      'subject-id': subjectId,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'jobName': jobName,
        'printMode': printMode,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = json.decode(response.body);
      print('printSetting successfully: responseBody $responseBody');
      final responseData = responseBody['data'];
      print('printSetting successfully: responseData $responseData');
      return responseData;
    } else {
      throw Exception('Failed to set print settings');
    }
  }

  Future<String> uploadPrintFile(String uploadUri, String filePath) async {
    final uri =
        Uri.parse('$baseUrl/epson/upload-print-file').replace(queryParameters: {
      'upload-uri': uploadUri,
    });
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      filePath,
      filename: basename(filePath),
    ));

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);

    print('Upload print file response: ${responseData.body}');

    if (responseData.statusCode == 200 || responseData.statusCode == 201) {
      return 'success';
    } else {
      throw Exception('Failed to upload print file');
    }
  }

  Future<Map<String, dynamic>> executePrint(
    String accessToken,
    String subjectId,
    String jobId,
  ) async {
    final uri =
        Uri.parse('$baseUrl/epson/execute-print').replace(queryParameters: {
      'access-token': accessToken,
      'subject-id': subjectId,
      'job-id': jobId,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    print('Execute print response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = json.decode(response.body);
      return responseBody['data'];
    } else {
      throw Exception('Failed to execute print');
    }
  }
}
