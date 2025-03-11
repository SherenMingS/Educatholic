import 'package:flutter/material.dart';
import 'package:frontend/screen/isiquiz_siswa.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz.dart';
import '../services/api_service.dart';

class StudentQuizListPage extends StatefulWidget {
  @override
  _StudentQuizListPageState createState() => _StudentQuizListPageState();
}

class _StudentQuizListPageState extends State<StudentQuizListPage> {
  List<Quiz> quizzes = [];
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndClassAndFetchQuizzes();
  }

  Future<void> _loadTokenAndClassAndFetchQuizzes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('token');
    String? savedClass = prefs.getString('kelas'); // Ambil kelas siswa

    print("Token: $savedToken | Kelas: $savedClass"); // Debugging

    if (savedToken != null && savedClass != null) {
      setState(() {
        token = savedToken;
        _fetchQuizzes(savedClass); // Kirim kelas ke API
      });
    }
  }

  Future<void> _fetchQuizzes(String kelas) async {
    setState(() {
      isLoading = true;
    });

    try {
      final quizzesList = await ApiService.getQuizzesForStudents(token!, kelas);
      setState(() {
        quizzes = quizzesList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat kuis untuk kelas $kelas: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Kuis Siswa'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : quizzes.isEmpty
              ? Center(child: Text('Belum ada kuis tersedia'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Icon(Icons.assignment, color: Colors.blue),
                        title: Text(
                          quiz.title,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Kelas: ${quiz.kelas} | ${quiz.questionCount} Soal",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizPage(quizId: quiz.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
