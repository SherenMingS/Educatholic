import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz.dart';
import '../services/api_service.dart';
import 'tambahquiz_guru.dart';
import 'editquiz_guru.dart';
import 'package:frontend/widgets/custom_appbar.dart';
import 'package:frontend/widgets/empty_bottombar.dart';

class QuizListPage extends StatefulWidget {
  @override
  _QuizListPageState createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  List<Quiz> quizzes = [];
  String? token;
  String? selectedClass;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndClass();
  }

  Future<void> _loadTokenAndClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('token');
    String? savedClass = prefs.getString('kelas_guru');

    if (savedToken != null && savedClass != null) {
      setState(() {
        token = savedToken;
        selectedClass = savedClass;
      });
      _fetchQuizzes();
    }
  }

  Future<void> _fetchQuizzes() async {
    setState(() => isLoading = true);

    try {
      final quizzesList = await ApiService.getQuizzes(token!, selectedClass!);
      setState(() {
        quizzes = quizzesList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat kuis: $e")),
      );
    }
  }

  Future<void> _deleteQuiz(int quizId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi Hapus"),
        content: Text("Apakah Anda yakin ingin menghapus kuis ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        await ApiService.deleteQuiz(quizId, token!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Quiz berhasil dihapus")),
        );
        _fetchQuizzes();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus quiz: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomPageAppBar(
        icon: Icons.assignment,
        title: 'Daftar Kuis (${selectedClass ?? "Loading..."})',
      ),
      bottomNavigationBar: const EmptyBottomBar(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : quizzes.isEmpty
              ? Center(child: Text('Belum ada kuis untuk kelas $selectedClass'))
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
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.assignment, color: Colors.blue),
                        ),
                        title: Text(
                          quiz.title,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            Text(
                              "Kelas: ${quiz.kelas} | ${quiz.questionCount} Soal",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Durasi: ${quiz.duration} Menit",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            if (quiz.deadline != null)
                              Text(
                                "Deadline: ${quiz.deadline}",
                                style:
                                    TextStyle(fontSize: 14, color: Colors.red),
                              ),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 10,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EditQuizPage(quiz: quiz)),
                                );
                                if (result == true) _fetchQuizzes();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteQuiz(quiz.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddQuizPage()),
          );
          if (result == true) _fetchQuizzes();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
