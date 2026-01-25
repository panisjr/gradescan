class AnswerKey {
  final String id;
  final String name;
  final int totalItems;
  final List<String> answers;
  final DateTime createdAt;

  AnswerKey({
    required this.id,
    required this.name,
    required this.totalItems,
    required this.answers,
    required this.createdAt,
  });
}

class Student {
  final String id;
  final String name;
  final String? section;

  Student({required this.id, required this.name, this.section});
}

class ScanResult {
  final String id;
  final String studentName;
  final int score;
  final int totalItems;
  final List<String> studentAnswers;
  final List<String> correctAnswers;
  final DateTime scannedAt;
  final String answerKeyName;
  final String? imagePath;

  ScanResult({
    required this.id,
    required this.studentName,
    required this.score,
    required this.totalItems,
    required this.studentAnswers,
    required this.correctAnswers,
    required this.scannedAt,
    required this.answerKeyName,
    this.imagePath,
  });

  double get percentage => (score / totalItems) * 100;
}

class Exam {
  final String id;
  final String name;
  final AnswerKey answerKey;
  final List<ScanResult> results;
  final DateTime createdAt;

  Exam({
    required this.id,
    required this.name,
    required this.answerKey,
    required this.results,
    required this.createdAt,
  });
}
