import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class FormReadService {
  // Replace with your actual FormRead API key
  static const String _apiKey = 'YOUR_FORMREAD_API_KEY';
  static const String _baseUrl = 'https://api.formread.com/v1';

  // Alternative: Use environment variables
  // static String get _apiKey => const String.fromEnvironment('FORMREAD_API_KEY');

  /// Scan an answer sheet image and extract bubble answers
  static Future<FormReadResult> scanAnswerSheet({
    required File imageFile,
    required int totalQuestions,
    int optionsPerQuestion = 4, // A, B, C, D
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/omr/scan'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      });

      // Add form fields
      request.fields['total_questions'] = totalQuestions.toString();
      request.fields['options_per_question'] = optionsPerQuestion.toString();
      request.fields['output_format'] = 'json';

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return FormReadResult.fromJson(jsonData);
      } else {
        debugPrint('FormRead API Error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        throw FormReadException(
          'API Error: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      debugPrint('FormRead Service Error: $e');
      rethrow;
    }
  }

  /// Alternative method using base64 encoded image
  static Future<FormReadResult> scanAnswerSheetBase64({
    required String base64Image,
    required int totalQuestions,
    int optionsPerQuestion = 4,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/omr/scan'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'image': base64Image,
          'total_questions': totalQuestions,
          'options_per_question': optionsPerQuestion,
          'output_format': 'json',
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return FormReadResult.fromJson(jsonData);
      } else {
        throw FormReadException(
          'API Error: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      debugPrint('FormRead Service Error: $e');
      rethrow;
    }
  }
}

/// Result from FormRead API
class FormReadResult {
  final bool success;
  final String? studentId;
  final String? studentName;
  final List<String> answers;
  final double confidence;
  final String? rawResponse;
  final List<QuestionResult>? detailedResults;

  FormReadResult({
    required this.success,
    this.studentId,
    this.studentName,
    required this.answers,
    required this.confidence,
    this.rawResponse,
    this.detailedResults,
  });

  factory FormReadResult.fromJson(Map<String, dynamic> json) {
    // Parse answers from various possible response formats
    List<String> parsedAnswers = [];

    if (json['answers'] != null) {
      if (json['answers'] is List) {
        parsedAnswers = (json['answers'] as List).map((e) {
          if (e is Map) {
            return (e['selected'] ?? e['answer'] ?? '-')
                .toString()
                .toUpperCase();
          }
          return e.toString().toUpperCase();
        }).toList();
      } else if (json['answers'] is Map) {
        // Handle map format: {"1": "A", "2": "B", ...}
        final answersMap = json['answers'] as Map;
        final sortedKeys = answersMap.keys.toList()
          ..sort(
            (a, b) =>
                int.parse(a.toString()).compareTo(int.parse(b.toString())),
          );
        parsedAnswers = sortedKeys
            .map((k) => answersMap[k].toString().toUpperCase())
            .toList();
      }
    }

    // Parse detailed results if available
    List<QuestionResult>? detailed;
    if (json['detailed_results'] != null || json['questions'] != null) {
      final detailList = json['detailed_results'] ?? json['questions'];
      if (detailList is List) {
        detailed = detailList.map((e) => QuestionResult.fromJson(e)).toList();
      }
    }

    return FormReadResult(
      success: json['success'] ?? json['status'] == 'success' ?? true,
      studentId: json['student_id'] ?? json['studentId'] ?? json['id'],
      studentName: json['student_name'] ?? json['studentName'] ?? json['name'],
      answers: parsedAnswers,
      confidence: (json['confidence'] ?? json['accuracy'] ?? 0.95).toDouble(),
      rawResponse: json.toString(),
      detailedResults: detailed,
    );
  }
}

/// Detailed result for each question
class QuestionResult {
  final int questionNumber;
  final String selectedAnswer;
  final double confidence;
  final Map<String, double>? optionConfidences;

  QuestionResult({
    required this.questionNumber,
    required this.selectedAnswer,
    required this.confidence,
    this.optionConfidences,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    Map<String, double>? optConf;
    if (json['options'] != null || json['option_confidences'] != null) {
      final opts = json['options'] ?? json['option_confidences'];
      if (opts is Map) {
        optConf = opts.map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        );
      }
    }

    return QuestionResult(
      questionNumber: json['question'] ?? json['number'] ?? json['q'] ?? 0,
      selectedAnswer: (json['selected'] ?? json['answer'] ?? '-')
          .toString()
          .toUpperCase(),
      confidence: (json['confidence'] ?? json['score'] ?? 1.0).toDouble(),
      optionConfidences: optConf,
    );
  }
}

/// Custom exception for FormRead errors
class FormReadException implements Exception {
  final String message;
  final String? details;

  FormReadException(this.message, [this.details]);

  @override
  String toString() =>
      'FormReadException: $message${details != null ? '\nDetails: $details' : ''}';
}
