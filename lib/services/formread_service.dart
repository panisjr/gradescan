import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

/// OCR Service using free providers
class OCRService {
  // OCR.space free API key (get yours at https://ocr.space/ocrapi/freekey)
  static const String _ocrSpaceApiKey =
      'K85947648788957'; // Free test key, replace with yours

  /// Primary method: On-device OCR using Google ML Kit (FREE, no internet needed)
  static Future<OMRResult> scanWithMLKit({
    required File imageFile,
    required int totalQuestions,
    int optionsPerQuestion = 4,
  }) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);

      debugPrint('ML Kit recognized text:\n${recognizedText.text}');

      // Parse the recognized text to extract answers
      final answers = _parseAnswersFromText(
        recognizedText.text,
        totalQuestions,
        optionsPerQuestion,
      );

      // Try to extract student info
      final studentInfo = _extractStudentInfo(recognizedText.text);

      return OMRResult(
        success: true,
        answers: answers,
        studentName: studentInfo['name'],
        studentId: studentInfo['id'],
        confidence: _calculateConfidence(answers, totalQuestions),
        rawText: recognizedText.text,
        provider: 'Google ML Kit (Offline)',
      );
    } catch (e) {
      debugPrint('ML Kit Error: $e');
      rethrow;
    } finally {
      textRecognizer.close();
    }
  }

  /// Fallback method: OCR.space cloud API (FREE tier: 25,000 requests/month)
  static Future<OMRResult> scanWithOCRSpace({
    required File imageFile,
    required int totalQuestions,
    int optionsPerQuestion = 4,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.ocr.space/parse/image'),
        headers: {'apikey': _ocrSpaceApiKey},
        body: {
          'base64Image': 'data:image/jpeg;base64,$base64Image',
          'language': 'eng',
          'isOverlayRequired': 'false',
          'detectOrientation': 'true',
          'scale': 'true',
          'OCREngine': '2', // Engine 2 is better for printed text
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['IsErroredOnProcessing'] == true) {
          throw OCRException(
            'OCR.space processing error',
            jsonData['ErrorMessage']?.toString(),
          );
        }

        final parsedResults = jsonData['ParsedResults'] as List?;
        if (parsedResults != null && parsedResults.isNotEmpty) {
          final text = parsedResults[0]['ParsedText'] as String? ?? '';

          debugPrint('OCR.space recognized text:\n$text');

          final answers = _parseAnswersFromText(
            text,
            totalQuestions,
            optionsPerQuestion,
          );
          final studentInfo = _extractStudentInfo(text);

          return OMRResult(
            success: true,
            answers: answers,
            studentName: studentInfo['name'],
            studentId: studentInfo['id'],
            confidence: _calculateConfidence(answers, totalQuestions),
            rawText: text,
            provider: 'OCR.space (Cloud)',
          );
        }
      }

      throw OCRException(
        'OCR.space Error: ${response.statusCode}',
        response.body,
      );
    } catch (e) {
      debugPrint('OCR.space Error: $e');
      rethrow;
    }
  }

  /// Smart answer parsing from OCR text
  static List<String> _parseAnswersFromText(
    String text,
    int totalQuestions,
    int optionsPerQuestion,
  ) {
    List<String> answers = List.filled(totalQuestions, '-');

    // Clean and normalize text
    final cleanText = text
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();

    final lines = cleanText.split('\n');

    // Multiple parsing strategies

    // Strategy 1: Look for patterns like "1. A" or "1) A" or "1: A" or "1 A"
    final pattern1 = RegExp(
      r'(\d+)\s*[\.\)\:\-]?\s*([A-Ea-e])\b',
      multiLine: true,
    );
    for (final match in pattern1.allMatches(cleanText)) {
      final questionNum = int.tryParse(match.group(1) ?? '');
      final answer = match.group(2)?.toUpperCase();

      if (questionNum != null &&
          answer != null &&
          questionNum >= 1 &&
          questionNum <= totalQuestions) {
        answers[questionNum - 1] = answer;
      }
    }

    // Strategy 2: Look for circled/marked answers in format "①A ②B ③C"
    final pattern2 = RegExp(
      r'[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳㉑㉒㉓㉔㉕]\s*([A-Ea-e])',
      multiLine: true,
    );
    int idx = 0;
    for (final match in pattern2.allMatches(cleanText)) {
      final answer = match.group(1)?.toUpperCase();
      if (answer != null && idx < totalQuestions) {
        answers[idx] = answer;
        idx++;
      }
    }

    // Strategy 3: Look for answer grid patterns
    // Common formats: "A B C D" or "A|B|C|D" or "[A] [B] [C] [D]"
    final pattern3 = RegExp(
      r'\b([A-Ea-e])\s*[\|\[\]\(\)●○◯◉■□✓✗xX]?\s*',
      multiLine: true,
    );

    // Strategy 4: Parse line by line for question-answer pairs
    for (int i = 0; i < lines.length && i < totalQuestions; i++) {
      final line = lines[i].trim();

      // Check if line contains a single answer letter
      final singleLetterMatch = RegExp(r'^([A-Ea-e])$').firstMatch(line);
      if (singleLetterMatch != null && answers[i] == '-') {
        answers[i] = singleLetterMatch.group(1)!.toUpperCase();
        continue;
      }

      // Check for marked/selected answer patterns
      // Patterns like: "[X]A [ ]B [ ]C [ ]D" or "●A ○B ○C ○D"
      final markedPattern = RegExp(
        r'[\[●◉■✓xX]\s*([A-Ea-e])|([A-Ea-e])\s*[\]●◉■✓xX]',
      );
      final markedMatch = markedPattern.firstMatch(line);
      if (markedMatch != null && answers[i] == '-') {
        answers[i] = (markedMatch.group(1) ?? markedMatch.group(2))!
            .toUpperCase();
      }
    }

    // Strategy 5: Look for answer key format "ABCD ABCD ABCD..."
    final allLettersPattern = RegExp(r'^[A-Ea-e\s]+$');
    for (final line in lines) {
      if (allLettersPattern.hasMatch(line.trim())) {
        final letterMatches = RegExp(r'[A-Ea-e]').allMatches(line);
        int qNum = 0;
        for (final match in letterMatches) {
          if (qNum < totalQuestions && answers[qNum] == '-') {
            answers[qNum] = match.group(0)!.toUpperCase();
          }
          qNum++;
        }
      }
    }

    debugPrint('Parsed answers: $answers');
    return answers;
  }

  /// Extract student information from text
  static Map<String, String?> _extractStudentInfo(String text) {
    String? name;
    String? id;

    // Look for name patterns
    final namePatterns = [
      RegExp(
        r'(?:name|student|nombre)\s*[:=]?\s*([A-Za-z\s]+)',
        caseSensitive: false,
      ),
      RegExp(r'^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)$', multiLine: true),
    ];

    for (final pattern in namePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        name = match.group(1)?.trim();
        if (name != null && name.length > 2) break;
      }
    }

    // Look for ID patterns
    final idPatterns = [
      RegExp(
        r'(?:id|student\s*id|number|no\.?)\s*[:=]?\s*(\d+)',
        caseSensitive: false,
      ),
      RegExp(r'\b(\d{5,10})\b'), // 5-10 digit number
    ];

    for (final pattern in idPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        id = match.group(1);
        break;
      }
    }

    return {'name': name, 'id': id};
  }

  /// Calculate confidence based on how many answers were detected
  static double _calculateConfidence(List<String> answers, int total) {
    final detected = answers.where((a) => a != '-').length;
    return detected / total;
  }

  /// Combined scan: Try ML Kit first, fallback to OCR.space
  static Future<OMRResult> scan({
    required File imageFile,
    required int totalQuestions,
    int optionsPerQuestion = 4,
    bool preferCloud = false,
  }) async {
    if (preferCloud) {
      try {
        return await scanWithOCRSpace(
          imageFile: imageFile,
          totalQuestions: totalQuestions,
          optionsPerQuestion: optionsPerQuestion,
        );
      } catch (e) {
        debugPrint('Cloud OCR failed, falling back to on-device: $e');
        return await scanWithMLKit(
          imageFile: imageFile,
          totalQuestions: totalQuestions,
          optionsPerQuestion: optionsPerQuestion,
        );
      }
    } else {
      try {
        final result = await scanWithMLKit(
          imageFile: imageFile,
          totalQuestions: totalQuestions,
          optionsPerQuestion: optionsPerQuestion,
        );

        // If confidence is too low, try cloud
        if (result.confidence < 0.5) {
          debugPrint(
            'Low confidence (${result.confidence}), trying cloud OCR...',
          );
          try {
            return await scanWithOCRSpace(
              imageFile: imageFile,
              totalQuestions: totalQuestions,
              optionsPerQuestion: optionsPerQuestion,
            );
          } catch (e) {
            return result; // Return original if cloud fails
          }
        }

        return result;
      } catch (e) {
        debugPrint('On-device OCR failed, trying cloud: $e');
        return await scanWithOCRSpace(
          imageFile: imageFile,
          totalQuestions: totalQuestions,
          optionsPerQuestion: optionsPerQuestion,
        );
      }
    }
  }
}

/// Result from OCR scanning
class OMRResult {
  final bool success;
  final List<String> answers;
  final String? studentName;
  final String? studentId;
  final double confidence;
  final String? rawText;
  final String provider;

  OMRResult({
    required this.success,
    required this.answers,
    this.studentName,
    this.studentId,
    required this.confidence,
    this.rawText,
    required this.provider,
  });

  @override
  String toString() {
    return 'OMRResult(success: $success, answers: $answers, confidence: $confidence, provider: $provider)';
  }
}

/// Custom exception for OCR errors
class OCRException implements Exception {
  final String message;
  final String? details;

  OCRException(this.message, [this.details]);

  @override
  String toString() =>
      'OCRException: $message${details != null ? '\nDetails: $details' : ''}';
}
