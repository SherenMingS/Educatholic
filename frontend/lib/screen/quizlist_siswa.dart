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

class StudentQuizListPage extends StatefulWidget {
  @override
  _StudentQuizListPageState createState() => _StudentQuizListPageState();
}

class _StudentQuizListPageState extends State<StudentQuizListPage> {
  List<Quiz> quizzes = [];
  String? token;
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
      _fetchQuizzes(savedClass);
    } else {
      print("Token atau Kelas tidak ditemukan");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchQuizzes(String kelas) async {
    try {
      final quizzesList = await ApiService.getQuizzesForStudents(token!, kelas);
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

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MateriPage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentQuizListPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardSiswa()),
        );
        break;
      case 3:
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? savedToken = prefs.getString('token');

        if (savedToken != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => LeaderboardScreen(token: savedToken)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token tidak ditemukan')),
          );
        }
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage()),
        );
        break;
      default:
        break;
    }
  }

  void _checkQuizStatus(int quizId) async {
    try {
      final result = await ApiService.checkQuizStatus(token!, quizId);

      // Jika statusnya berhasil, lanjutkan ke halaman kuis
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuizPage(quizId: quizId)),
      );
    } catch (e) {
      // Jika error, tampilkan dialog error
      if (e.toString().contains('Anda sudah mengerjakan kuis ini')) {
        _showQuizAlreadyCompletedDialog();
      } else {
        _showErrorDialog();
      }
      print('Error: $e'); // Log error untuk debugging
    }
  }

// Dialog untuk menampilkan jika kuis sudah dikerjakan
  void _showQuizAlreadyCompletedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Peringatan"),
          content: Text("Anda sudah mengerjakan kuis ini."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Menutup dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

// Dialog untuk menampilkan jika materi belum dibaca (locked)
  void _showQuizLockedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Peringatan"),
          content: Text("Anda perlu membaca materi terlebih dahulu."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Menutup dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

// Dialog error untuk pengecekan kuis gagal
  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text("Terjadi kesalahan dalam memeriksa status kuis."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Menutup dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kuis Siswa'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : quizzes.isEmpty
              ? const Center(child: Text('Belum ada kuis tersedia'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) =>
                      _buildQuizCard(quizzes[index]),
                ),
      bottomNavigationBar: _buildCurvedNavBar(),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    final isLocked = !quiz.isRead; // If the material is not read, lock the quiz

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          isLocked ? Icons.lock : Icons.assignment,
          color: isLocked ? Colors.grey : Colors.blue,
        ),
        title: Text(
          quiz.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Kelas: ${quiz.kelas} | ${quiz.questionCount} Soal",
          style: TextStyle(
            fontSize: 14,
            color: isLocked ? Colors.grey : Colors.black54,
          ),
        ),
        trailing: Icon(
          isLocked ? Icons.lock : Icons.arrow_forward_ios,
          size: 18,
          color: isLocked ? Colors.grey : Colors.blue,
        ),
        onTap: isLocked
            ? () {
                _showQuizLockedDialog(); // Show locked dialog
              }
            : () {
                _checkQuizStatus(quiz.id); // Check if the quiz can be attempted
              },
      ),
    );
  }

  Widget _buildCurvedNavBar() {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: Colors.blue,
      height: 70,
      index: _selectedIndex,
      animationDuration: const Duration(milliseconds: 300),
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
}
