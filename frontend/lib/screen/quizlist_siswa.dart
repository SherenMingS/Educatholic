import 'package:flutter/material.dart';
import 'package:frontend/screen/isiquiz_siswa.dart';
import 'package:frontend/screen/materi_siswa.dart';
import 'package:frontend/screen/dashboard_siswa.dart';
import 'package:frontend/screen/leaderboard_siswa.dart';
import 'package:frontend/screen/profile_siswa.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz.dart';
import '../services/api_service.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../widgets/custom_appbar.dart';

class StudentQuizListPage extends StatefulWidget {
  @override
  _StudentQuizListPageState createState() => _StudentQuizListPageState();
}

class _StudentQuizListPageState extends State<StudentQuizListPage> {
  List<Quiz> quizzes = [];
  Map<int, bool> canRetryMap = {};
  String? token;
  String selectedSemester = '1';
  bool isLoading = true;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchQuizzes();
  }

  Future<void> _loadTokenAndFetchQuizzes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('token');
    String? savedClass = prefs.getString('kelas');

    if (savedToken != null && savedClass != null) {
      token = savedToken;
      await _fetchQuizzes(savedClass);
    }
    setState(() => isLoading = false);
  }

  Future<void> _fetchQuizzes(String kelas) async {
    try {
      final quizzesList = await ApiService.getQuizzesForStudents(token!, kelas, semester: selectedSemester);
      final retryMap = <int, bool>{};

      for (var quiz in quizzesList) {
        try {
          final result = await ApiService.checkQuizStatus(token!, quiz.id);
          retryMap[quiz.id] = result['can_retry'] == true;
          quiz.lastScore = result['last_score']?.toDouble();
          quiz.currentAttempts = result['current_attempts'];
          quiz.maxAttempts = result['max_attempts'];
        } catch (e) {
          retryMap[quiz.id] = false;
          quiz.lastScore = null;
          quiz.currentAttempts = null;
          quiz.maxAttempts = quiz.maxAttempts ?? 1;
        }
      }

      setState(() {
        quizzes = quizzesList;
        canRetryMap = retryMap;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat kuis: $e")),
      );
    }
  }

  void _checkQuizStatus(int quizId) async {
    try {
      final result = await ApiService.checkQuizStatus(token!, quizId);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuizPage(quizId: quizId)),
      );
    } catch (e) {
      if (e.toString().contains('sudah mengerjakan')) {
        _showDialog("Peringatan", "Anda sudah mengerjakan kuis ini.");
      } else {
        _showDialog("Error", "Terjadi kesalahan saat memeriksa status kuis.");
      }
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          CustomPageAppBar(title: 'Daftar Kuis Siswa', icon: Icons.assignment),
      bottomNavigationBar: _buildCurvedNavBar(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔽 Filter semester
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text("Semester:", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 12),
                      DropdownButton<String>(
                        value: selectedSemester,
                        items: ['1', '2'].map((sem) {
                          return DropdownMenuItem(value: sem, child: Text("Semester $sem"));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedSemester = val!;
                            _loadTokenAndFetchQuizzes(); // Fetch ulang
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: quizzes.isEmpty
                      ? Center(child: Text('Belum ada kuis tersedia'))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: quizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = quizzes[index];
                            final canRetry = canRetryMap[quiz.id] ?? false;
                            return _buildQuizCard(quiz, canRetry: canRetry);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuizCard(Quiz quiz, {bool canRetry = false}) {
    final isLocked = !quiz.isRead;
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Icon(
          isLocked ? Icons.lock : Icons.assignment,
          color: isLocked ? Colors.grey : theme.iconTheme.color,
        ),
        title: Text(
          quiz.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kelas: ${quiz.kelas} | ${quiz.questionCount} Soal"),
            SizedBox(height: 4),
            Text(
              "Skor Terakhir: ${quiz.lastScore != null ? quiz.lastScore!.toStringAsFixed(1) : '-'} | Attempt: ${quiz.currentAttempts ?? '-'} / ${quiz.maxAttempts ?? '-'}",
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 6),
            if (canRetry && (quiz.currentAttempts ?? 0) > 0)
              ElevatedButton.icon(
                onPressed: () => _checkQuizStatus(quiz.id),
                icon: Icon(Icons.refresh),
                label: Text("Coba Lagi"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              )
            else if ((quiz.lastScore != null && quiz.lastScore! >= quiz.kkm!))
              ElevatedButton.icon(
                onPressed: () => _showDialog(
                  "Kuis Tidak Bisa Diulang",
                  "Kamu sudah mengerjakan kuis ini dan nilaimu sudah mencapai atau melebihi KKM.",
                ),
                icon: Icon(Icons.info_outline),
                label: Text("Lihat Info"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              )
            else if ((quiz.lastScore != null &&
                quiz.lastScore! < quiz.kkm! &&
                quiz.currentAttempts == quiz.maxAttempts))
              ElevatedButton.icon(
                onPressed: () => _showDialog(
                  "Kuis Tidak Bisa Diulang",
                  "Kamu telah mencapai batas maksimal percobaan (${quiz.maxAttempts})",
                ),
                icon: Icon(Icons.info_outline),
                label: Text("Lihat Info"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
          ],
        ),
        trailing: Icon(
          isLocked ? Icons.lock : Icons.arrow_forward_ios,
          size: 18,
          color: isLocked ? Colors.grey : theme.iconTheme.color,
        ),
        onTap: isLocked
            ? () => _showDialog("Peringatan", "Baca materi terlebih dahulu.")
            : (!canRetry
                ? () => _showDialog("Kuis Tidak Bisa Diulang",
                    "Kamu tidak dapat mengerjakan kuis ini lagi.")
                : () => _checkQuizStatus(quiz.id)),
      ),
    );
  }

  Widget _buildCurvedNavBar() {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: Colors.blue,
      height: 70,
      index: _selectedIndex,
      animationDuration: Duration(milliseconds: 300),
      items: [
        Icon(Icons.menu_book,
            size: 28,
            color: _selectedIndex == 0 ? Colors.yellow : Colors.white),
        Icon(Icons.assignment,
            size: 28,
            color: _selectedIndex == 1 ? Colors.yellow : Colors.white),
        Icon(Icons.home,
            size: 28,
            color: _selectedIndex == 2 ? Colors.yellow : Colors.white),
        Icon(Icons.emoji_events,
            size: 28,
            color: _selectedIndex == 3 ? Colors.yellow : Colors.white),
        Icon(Icons.person,
            size: 28,
            color: _selectedIndex == 4 ? Colors.yellow : Colors.white),
      ],
      onTap: _onItemTapped,
    );
  }

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => MateriPage()));
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => DashboardSiswa()));
        break;
      case 3:
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? savedToken = prefs.getString('token');
        if (savedToken != null) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => LeaderboardScreen(token: savedToken)));
        }
        break;
      case 4:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => ProfilePage()));
        break;
    }
  }
}
