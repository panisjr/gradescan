import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Alternative OMR services configuration
class OMRService {
  // You can use multiple services as fallback

  /// Option 1: Google Cloud Vision API
  static Future<List<String>> scanWithGoogleVision({
    required File imageFile,
    required int totalQuestions,
  }) async {
    const apiKey = 'YOUR_GOOGLE_CLOUD_API_KEY';
    const url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION'},
              {'type': 'OBJECT_LOCALIZATION'},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseGoogleVisionResponse(data, totalQuestions);
    }

    throw Exception('Google Vision API Error: ${response.statusCode}');
  }

  static List<String> _parseGoogleVisionResponse(
    Map<String, dynamic> data,
    int total,
  ) {
    // Parse the response and extract answers
    // This is a simplified example - actual implementation depends on your answer sheet format
    List<String> answers = List.filled(total, '-');

    try {
      final responses = data['responses'] as List;
      if (responses.isNotEmpty) {
        final textAnnotations = responses[0]['textAnnotations'] as List?;
        if (textAnnotations != null && textAnnotations.isNotEmpty) {
          final fullText = textAnnotations[0]['description'] as String;
          // Parse the text to find answer patterns
          // This is highly dependent on your answer sheet format
          debugPrint('OCR Text: $fullText');
        }
      }
    } catch (e) {
      debugPrint('Error parsing Google Vision response: $e');
    }

    return answers;
  }

  /// Option 2: Azure Form Recognizer
  static Future<List<String>> scanWithAzureFormRecognizer({
    required File imageFile,
    required int totalQuestions,
  }) async {
    const endpoint = 'YOUR_AZURE_ENDPOINT';
    const apiKey = 'YOUR_AZURE_API_KEY';

    final bytes = await imageFile.readAsBytes();

    // Start analysis
    final analyzeResponse = await http.post(
      Uri.parse('$endpoint/formrecognizer/v2.1/layout/analyze'),
      headers: {
        'Content-Type': 'application/octet-stream',
        'Ocp-Apim-Subscription-Key': apiKey,
      },
      body: bytes,
    );

    if (analyzeResponse.statusCode == 202) {
      final operationLocation = analyzeResponse.headers['operation-location'];
      if (operationLocation != null) {
        // Poll for results
        return await _pollAzureResults(
          operationLocation,
          apiKey,
          totalQuestions,
        );
      }
    }

    throw Exception(
      'Azure Form Recognizer Error: ${analyzeResponse.statusCode}',
    );
  }

  static Future<List<String>> _pollAzureResults(
    String operationUrl,
    String apiKey,
    int totalQuestions,
  ) async {
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 2));

      final response = await http.get(
        Uri.parse(operationUrl),
        headers: {'Ocp-Apim-Subscription-Key': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'succeeded') {
          return _parseAzureResponse(data, totalQuestions);
        }
      }
    }

    throw Exception('Azure Form Recognizer: Timeout waiting for results');
  }

  static List<String> _parseAzureResponse(
    Map<String, dynamic> data,
    int total,
  ) {
    List<String> answers = List.filled(total, '-');
    // Parse Azure response based on your form structure
    return answers;
  }

  /// Option 3: Custom OMR API (if you have your own backend)
  static Future<List<String>> scanWithCustomAPI({
    required File imageFile,
    required int totalQuestions,
    required String apiUrl,
    String? apiKey,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    if (apiKey != null) {
      request.headers['Authorization'] = 'Bearer $apiKey';
    }

    request.fields['total_questions'] = totalQuestions.toString();
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['answers'] is List) {
        return (data['answers'] as List).map((e) => e.toString()).toList();
      }
    }

    throw Exception('Custom API Error: ${response.statusCode}');
  }
}
