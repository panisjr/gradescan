import 'package:flutter/material.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  List<AnswerKey> answerKeys = [];
  List<ScanResult> scanResults = [];
  List<Exam> exams = [];
  AnswerKey? selectedAnswerKey;

  void addAnswerKey(AnswerKey key) {
    answerKeys.add(key);
    notifyListeners();
  }

  void selectAnswerKey(AnswerKey? key) {
    selectedAnswerKey = key;
    notifyListeners();
  }

  void addScanResult(ScanResult result) {
    scanResults.insert(0, result);
    notifyListeners();
  }

  void deleteAnswerKey(String id) {
    answerKeys.removeWhere((key) => key.id == id);
    if (selectedAnswerKey?.id == id) {
      selectedAnswerKey = null;
    }
    notifyListeners();
  }

  void clearResults() {
    scanResults.clear();
    notifyListeners();
  }
}

// Global state instance
final appState = AppState();
