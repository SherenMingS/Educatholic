import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hasilquiz_siswa.dart'; // Import halaman hasil kuis

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

  void _submitQuiz() async {
    if (selectedAnswers.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Harap jawab semua pertanyaan!")),
      );
      return;
    }

    List<Map<String, dynamic>> answers = [];
    for (int i = 0; i < selectedAnswers.length; i++) {
      String selectedLetter =
          ""; // Tambahkan variabel untuk menyimpan huruf jawaban

      if (selectedAnswers[i] == quizData!['questions'][i]['option_1']) {
        selectedLetter = "A";
      } else if (selectedAnswers[i] == quizData!['questions'][i]['option_2']) {
        selectedLetter = "B";
      } else if (selectedAnswers[i] == quizData!['questions'][i]['option_3']) {
        selectedLetter = "C";
      } else if (selectedAnswers[i] == quizData!['questions'][i]['option_4']) {
        selectedLetter = "D";
      }

      print(
          "Mengirim Jawaban: Question ID: ${quizData!['questions'][i]['id']}, Answer: $selectedLetter");

      answers.add({
        "question_id": quizData!['questions'][i]['id'],
        "selected_answer": selectedLetter, // 🔥 Kirim huruf jawaban, bukan teks
      });
    }

    try {
      var result = await ApiService.submitQuiz(token!, widget.quizId, answers);
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
        title: Text(quizData!['title']),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// **Progress Indicator**
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
              currentQuestion['question'],
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
                      answer ?? "Pilihan tidak tersedia",
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
                currentQuestionIndex < questions.length - 1
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            currentQuestionIndex++;
                          });
                        },
                        child: Text("Selanjutnya"),
                      )
                    : ElevatedButton(
                        onPressed: _submitQuiz,
                        child: Text("Selesai"),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
