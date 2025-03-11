import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizPage extends StatefulWidget {
  final int quizId; // ID Kuis yang dipilih siswa

  QuizPage({required this.quizId});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  Map<String, dynamic>? quizData;
  bool isLoading = true;
  String? token;
  int currentQuestionIndex = 0;
  String? selectedAnswer;
  List<String?> selectedAnswers = [];

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
        });
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (quizData == null ||
        !quizData!.containsKey('questions') ||
        quizData!['questions'].isEmpty) {
      return Scaffold(
        body: Center(child: Text("⚠️ Tidak ada soal dalam kuis ini!")),
      );
    }

    var questions = quizData!['questions'];
    var currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(quizData!['title']), // Menampilkan judul kuis
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// **Timer & Progress Indicator**
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.timer, color: Colors.black54),
                Text(
                  "${quizData!['duration']} Menit",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            /// **Pertanyaan**
            Text(
              "Pertanyaan ${currentQuestionIndex + 1}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              currentQuestion['question'], // Menampilkan pertanyaan
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            /// **Pilihan Jawaban**
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
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedAnswers[currentQuestionIndex] == answer
                            ? Colors.blue
                            : Colors.black54,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: selectedAnswers[currentQuestionIndex] == answer
                          ? Colors.blue.shade100
                          : Colors.white,
                    ),
                    child: Text(
                      answer ?? "Pilihan tidak tersedia", // Pastikan tidak null
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            /// **Navigasi Soal**
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
                  child: Text("Sebelumnya"),
                ),
                ElevatedButton(
                  onPressed: currentQuestionIndex < questions.length - 1
                      ? () {
                          setState(() {
                            currentQuestionIndex++;
                          });
                        }
                      : null,
                  child: Text("Selanjutnya"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
