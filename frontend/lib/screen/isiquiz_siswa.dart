import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hasilquiz_siswa.dart'; // Import halaman hasil kuis

class QuizPage extends StatefulWidget {
  final int quizId;

  const QuizPage({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  Map<String, dynamic>? quizData;
  bool isLoading = true;
  String? token;
  int currentQuestionIndex = 0;
  List<String?> selectedAnswers = [];

  int _remainingSeconds = 0;
  Timer? _timer;
  bool isStarted = false; // Untuk kontrol sudah mulai kuis atau belum

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchQuiz();
  }

  Future<void> _loadTokenAndFetchQuiz() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    if (token != null) {
      try {
        var data = await ApiService.getQuizDetailSiswa(token!, widget.quizId);
        setState(() {
          quizData = data;
          isLoading = false;
          selectedAnswers = List.filled(data['questions'].length, null);
          _remainingSeconds = data['duration'] * 60;
        });

        // Setelah load selesai, langsung tampilkan dialog
        _showStartQuizDialog();
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Gagal memuat kuis: $e")),
        );
      }
    }
  }

  void _showStartQuizDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Gak bisa tap luar untuk nutup
      barrierColor: Colors.black.withOpacity(0.5), // Blur background
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Mulai Kuis'),
          content: const Text(
            'Apakah kamu siap untuk mulai mengerjakan kuis ini? '
            'Waktu akan langsung berjalan setelah kamu mulai.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // ⬅️ Keluar dari halaman kuis
              },
              child: const Text('Batal', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                setState(() {
                  isStarted = true;
                });
                _startTimer(); // Mulai timer
              },
              child: const Text('Mulai', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _autoSubmitQuiz();
      }
    });
  }

  void _autoSubmitQuiz() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏰ Waktu habis! Kuis akan disubmit.')),
    );
    _submitQuiz();
  }

  void _submitQuiz() async {
    if (selectedAnswers.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Harap jawab semua pertanyaan!")),
      );
      return;
    }

    List<Map<String, dynamic>> answers = [];
    for (int i = 0; i < selectedAnswers.length; i++) {
      String selectedLetter = "";

      if (selectedAnswers[i] == quizData!['questions'][i]['option_1']) {
        selectedLetter = "A";
      } else if (selectedAnswers[i] == quizData!['questions'][i]['option_2']) {
        selectedLetter = "B";
      } else if (selectedAnswers[i] == quizData!['questions'][i]['option_3']) {
        selectedLetter = "C";
      } else if (selectedAnswers[i] == quizData!['questions'][i]['option_4']) {
        selectedLetter = "D";
      }

      answers.add({
        "question_id": quizData!['questions'][i]['id'],
        "selected_answer": selectedLetter,
      });
    }

    try {
      var result = await ApiService.submitQuiz(token!, widget.quizId, answers);
      _timer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HasilKuisPage(
            totalSoal: quizData!['questions'].length,
            jawabanBenar: result['correct_answers'],
            skor: result['score'],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Gagal mengirim jawaban: $e")),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (quizData == null ||
        !quizData!.containsKey('questions') ||
        quizData!['questions'].isEmpty) {
      return const Scaffold(
        body: Center(child: Text("⚠️ Tidak ada soal dalam kuis ini!")),
      );
    }

    var questions = quizData!['questions'];
    var currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(quizData!['title']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isStarted
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Timer dan Nomor Soal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.timer, color: Colors.black54),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: List.generate(
                          questions.length,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: index == currentQuestionIndex
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Pertanyaan
                  Text(
                    "Pertanyaan ${currentQuestionIndex + 1}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentQuestion['question'],
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  /// Pilihan Jawaban
                  Column(
                    children: [
                      currentQuestion['option_1'],
                      currentQuestion['option_2'],
                      currentQuestion['option_3'],
                      currentQuestion['option_4'],
                    ].map((answer) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAnswers[currentQuestionIndex] = answer;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedAnswers[currentQuestionIndex] ==
                                      answer
                                  ? Colors.blue
                                  : Colors.black54,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color:
                                selectedAnswers[currentQuestionIndex] == answer
                                    ? Colors.blue.shade100
                                    : Colors.white,
                          ),
                          child: Text(
                            answer ?? "Pilihan tidak tersedia",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  /// Navigasi Soal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: currentQuestionIndex > 0
                            ? () {
                                setState(() {
                                  currentQuestionIndex--;
                                });
                              }
                            : null,
                        child: const Text("Sebelumnya"),
                      ),
                      currentQuestionIndex < questions.length - 1
                          ? ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentQuestionIndex++;
                                });
                              },
                              child: const Text("Selanjutnya"),
                            )
                          : ElevatedButton(
                              onPressed: _submitQuiz,
                              child: const Text("Selesai"),
                            ),
                    ],
                  ),
                ],
              )
            : const Center(
                child: Text(
                  'Menunggu untuk mulai kuis...',
                  style: TextStyle(fontSize: 18),
                ),
              ),
      ),
    );
  }
}
