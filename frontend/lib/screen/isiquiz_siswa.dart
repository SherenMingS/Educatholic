// Full code with clickable arrow pagination for QuizPage
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/empty_bottombar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hasilquiz_siswa.dart';

class QuizPage extends StatefulWidget {
  final int quizId;
  const QuizPage({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  Map<String, dynamic>? quizData;
  bool isLoading = true;
  bool isStarted = false;
  String? token;
  int currentQuestionIndex = 0;
  List<String?> selectedAnswers = [];
  int _remainingSeconds = 0;
  Timer? _timer;

  bool isFiftyUsed = false;
  bool isExtraTimeUsed = false;
  Map<int, Set<int>> eliminatedOptionsMap = {};

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
        _showStartQuizDialog();
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Gagal memuat kuis: $e")),
        );
      }
    }
  }

  void _showStartQuizDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Mulai Kuis'),
        content: Text('Apakah kamu siap? Timer akan langsung berjalan.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Batal', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isStarted = true);
              _startTimer();
            },
            child: Text('Mulai', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _autoSubmitQuiz();
      }
    });
  }

  void _autoSubmitQuiz() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⏰ Waktu habis! Kuis akan disubmit.')),
    );
    _submitQuiz();
  }

  void _useFiftyFifty() {
    var currentQuestion = quizData!['questions'][currentQuestionIndex];
    String correct = currentQuestion['correct_answer'];
    List<String> keys = ['A', 'B', 'C', 'D'];
    List<int> salah = [];

    for (int i = 0; i < 4; i++) {
      if (keys[i] != correct) salah.add(i);
    }

    salah.shuffle();
    eliminatedOptionsMap[currentQuestionIndex] = salah.take(2).toSet();

    setState(() {
      isFiftyUsed = true;
    });
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
      String selectedLetter = "";
      var q = quizData!['questions'][i];

      if (selectedAnswers[i] == q['option_1']) selectedLetter = "A";
      if (selectedAnswers[i] == q['option_2']) selectedLetter = "B";
      if (selectedAnswers[i] == q['option_3']) selectedLetter = "C";
      if (selectedAnswers[i] == q['option_4']) selectedLetter = "D";

      answers.add({
        "question_id": q['id'],
        "selected_answer": selectedLetter,
      });
    }

    try {
      var result = await ApiService.submitQuiz(token!, widget.quizId, answers);
      _timer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HasilKuisPage(
            totalSoal: quizData!['questions'].length,
            jawabanBenar: result['correct_answers'],
            skorTerbaru: (result['skor_terbaru'] ?? 0).toDouble(), // ✅ new
            skorAkhir: (result['score'] ?? 0).toDouble(), // ✅ existing
            jawabanSalah:
                List<Map<String, dynamic>>.from(result['jawaban_salah']),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Gagal submit: $e")),
      );
    }
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final rs = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rs.toString().padLeft(2, '0')}';
  }

  List<Widget> _buildEllipsisPagination(int total) {
    List<Widget> items = [];

    void addButton(int i) {
      items.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: () => setState(() => currentQuestionIndex = i),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: i == currentQuestionIndex
                ? Colors.blue
                : (selectedAnswers[i] != null ? Colors.green : Colors.grey),
            child: Text("${i + 1}",
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
      ));
    }

    // Tombol Prev
    items.add(IconButton(
      icon: Icon(Icons.chevron_left),
      onPressed: currentQuestionIndex > 0
          ? () => setState(() => currentQuestionIndex--)
          : null,
    ));

    if (total <= 5) {
      for (int i = 0; i < total; i++) addButton(i);
    } else {
      if (currentQuestionIndex <= 2) {
        for (int i = 0; i < 3; i++) addButton(i);
        items.add(Text("..."));
        addButton(total - 1);
      } else if (currentQuestionIndex >= total - 3) {
        addButton(0);
        items.add(Text("..."));
        for (int i = total - 3; i < total; i++) addButton(i);
      } else {
        addButton(0);
        items.add(Text("..."));
        addButton(currentQuestionIndex);
        items.add(Text("..."));
        addButton(total - 1);
      }
    }

    // Tombol Next
    items.add(IconButton(
      icon: Icon(Icons.chevron_right),
      onPressed: currentQuestionIndex < total - 1
          ? () => setState(() => currentQuestionIndex++)
          : null,
    ));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    var questions = quizData!['questions'];
    var current = questions[currentQuestionIndex];
    List<String?> options = [
      current['option_1'],
      current['option_2'],
      current['option_3'],
      current['option_4']
    ];
    List<String> labels = ['A', 'B', 'C', 'D'];
    Set<int> eliminated = eliminatedOptionsMap[currentQuestionIndex] ?? {};

    return WillPopScope(
      onWillPop: () async => !isStarted,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          automaticallyImplyLeading: !isStarted,
          title: Text(
            quizData!['title'],
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: EmptyBottomBar(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: isStarted
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Icon(Icons.timer),
                            SizedBox(width: 4),
                            Text(_formatTime(_remainingSeconds),
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold))
                          ]),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  _buildEllipsisPagination(questions.length),
                            ),
                          )
                        ]),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isFiftyUsed)
                          IconButton(
                            icon: Icon(Icons.filter_alt_off),
                            tooltip: '50:50 (Hapus 2 opsi)',
                            onPressed: _useFiftyFifty,
                          ),
                        if (!isExtraTimeUsed)
                          IconButton(
                            icon: Icon(Icons.timer),
                            tooltip: 'Tambah 20 detik',
                            onPressed: () {
                              setState(() {
                                _remainingSeconds += 20;
                                isExtraTimeUsed = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("⏱ Waktu ditambah 20 detik")),
                              );
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text("Pertanyaan ${currentQuestionIndex + 1}",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(current['question'],
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: List.generate(4, (i) {
                          if (eliminated.contains(i)) return SizedBox.shrink();
                          bool isSelected =
                              selectedAnswers[currentQuestionIndex] ==
                                  options[i];
                          return Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() =>
                                  selectedAnswers[currentQuestionIndex] =
                                      options[i]),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue.shade50
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                      child: Text(
                                        labels[i],
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        options[i] ?? '-',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isSelected
                                              ? Colors.blue[900]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: currentQuestionIndex > 0
                              ? () => setState(() => currentQuestionIndex--)
                              : null,
                          child: Text("Sebelumnya"),
                        ),
                        currentQuestionIndex < questions.length - 1
                            ? ElevatedButton(
                                onPressed: () =>
                                    setState(() => currentQuestionIndex++),
                                child: Text("Selanjutnya"),
                              )
                            : ElevatedButton(
                                onPressed: _submitQuiz,
                                child: Text("Selesai"),
                              ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: Text("Menunggu untuk mulai kuis...",
                      style: TextStyle(fontSize: 18))),
        ),
      ),
    );
  }
}
