class Quiz {
  final int id;
  final String title;
  final String kelas;
  final int duration;
  final String? deadline;
  final int? materiId;
  final int questionCount;
  final List<Question> questions;
  final bool isCompleted;
  final bool isRead;

  // ✅ Tambahan untuk retry kuis
  final int? kkm;
  int? maxAttempts;

  // ✅ Tambahan baru: untuk tampilkan info status
  double? lastScore;
  int? currentAttempts;

  Quiz({
    required this.id,
    required this.title,
    required this.kelas,
    required this.duration,
    this.deadline,
    this.materiId,
    required this.questionCount,
    required this.questions,
    required this.isCompleted,
    required this.isRead,
    this.kkm,
    this.maxAttempts,

    // ✅ Tambahan baru
    this.lastScore,
    this.currentAttempts,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      kelas: json['kelas'],
      duration: json['duration'],
      deadline: json['deadline'],
      materiId: json['materi_id'],
      questionCount: json['questions_count'] ?? 0,
      questions: json['questions'] != null
          ? (json['questions'] as List<dynamic>)
              .map((q) => Question.fromJson(q))
              .toList()
          : [],
      isCompleted: json['is_completed'] ?? false,
      isRead: json['is_read'] ?? false,
      kkm: json['kkm'],
      maxAttempts: json['max_attempts'],
    );
  }
}

class Question {
  final int id;
  final String question;
  final String option1;
  final String option2;
  final String option3;
  final String option4;
  final String correctAnswer;

  Question({
    required this.id,
    required this.question,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      option1: json['option_1'],
      option2: json['option_2'],
      option3: json['option_3'],
      option4: json['option_4'],
      correctAnswer: json['correct_answer'],
    );
  }
}
