import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/quiz.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/empty_bottombar.dart';

class EditQuizPage extends StatefulWidget {
  final Quiz quiz;

  EditQuizPage({required this.quiz});

  @override
  _EditQuizPageState createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController durationController;
  late TextEditingController deadlineController;
  late TextEditingController kelasController;
  DateTime? selectedDeadline;
  List<Map<String, TextEditingController>> questionControllers = [];
  String? token;
  List<Map<String, dynamic>> materiList = [];
  String? selectedMateriId;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.quiz.title);
    durationController =
        TextEditingController(text: widget.quiz.duration.toString());
    deadlineController =
        TextEditingController(text: widget.quiz.deadline ?? '');
    kelasController = TextEditingController(text: widget.quiz.kelas ?? '');
    selectedMateriId = widget.quiz.materiId?.toString();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    await _loadMateriList();
    _loadQuestions();
  }

  Future<void> _loadMateriList() async {
    if (token == null || kelasController.text.isEmpty) return;
    try {
      final materiData =
          await ApiService.getMateri(token!, kelasController.text);
      setState(() {
        materiList = List<Map<String, dynamic>>.from(materiData);
      });
    } catch (e) {
      print("❌ Gagal mengambil materi: $e");
    }
  }

  Future<void> _loadQuestions() async {
    if (token == null) return;
    try {
      final quizDetail = await ApiService.getQuizDetail(widget.quiz.id, token!);
      setState(() {
        questionControllers = quizDetail.questions.map((q) {
          return {
            "question": TextEditingController(text: q.question),
            "option_1": TextEditingController(text: q.option1),
            "option_2": TextEditingController(text: q.option2),
            "option_3": TextEditingController(text: q.option3),
            "option_4": TextEditingController(text: q.option4),
            "correct_answer": TextEditingController(text: q.correctAnswer),
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat soal: $e")),
      );
    }
  }

  Future<void> _pickDeadline() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDeadline ?? DateTime.now()),
      );
      if (pickedTime != null) {
        DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          selectedDeadline = finalDateTime;
          deadlineController.text =
              DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime);
        });
      }
    }
  }

  void _addQuestion() {
    setState(() {
      questionControllers.add({
        "question": TextEditingController(),
        "option_1": TextEditingController(),
        "option_2": TextEditingController(),
        "option_3": TextEditingController(),
        "option_4": TextEditingController(),
        "correct_answer": TextEditingController(text: "A"),
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      questionControllers.removeAt(index);
    });
  }

  Future<void> _submitQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (token == null) return;
    if (questionControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Minimal 1 soal harus ada!")),
      );
      return;
    }

    double scorePerQuestion = 100 / questionControllers.length;
    List<Map<String, dynamic>> questions = questionControllers.map((q) {
      return {
        "question": q["question"]!.text,
        "option_1": q["option_1"]!.text,
        "option_2": q["option_2"]!.text,
        "option_3": q["option_3"]!.text,
        "option_4": q["option_4"]!.text,
        "correct_answer": q["correct_answer"]!.text,
        "score": scorePerQuestion.toStringAsFixed(2),
      };
    }).toList();

    Map<String, dynamic> quizData = {
      "title": titleController.text,
      "kelas": kelasController.text,
      "materi_id": selectedMateriId,
      "duration": int.tryParse(durationController.text) ?? 30,
      "deadline":
          deadlineController.text.isNotEmpty ? deadlineController.text : null,
      "questions": questions,
    };

    try {
      await ApiService.updateQuiz(widget.quiz.id, quizData, token!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Quiz berhasil diperbarui")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memperbarui quiz: $e")),
      );
    }
  }

  Widget _buildFormField(String label, TextEditingController controller,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (val) =>
            val == null || val.isEmpty ? "$label tidak boleh kosong" : null,
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, TextEditingController> q) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFormField("Pertanyaan", q["question"]!),
            _buildFormField("Opsi A", q["option_1"]!),
            _buildFormField("Opsi B", q["option_2"]!),
            _buildFormField("Opsi C", q["option_3"]!),
            _buildFormField("Opsi D", q["option_4"]!),
            DropdownButtonFormField<String>(
              value: q["correct_answer"]!.text,
              decoration: InputDecoration(
                labelText: "Jawaban Benar",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ["A", "B", "C", "D"]
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => q["correct_answer"]!.text = val!),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _removeQuestion(index),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Hapus Soal"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomPageAppBar(
        title: 'Edit Kuis',
        icon: Icons.edit, // Provide an appropriate icon
      ),
      bottomNavigationBar: EmptyBottomBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildFormField("Judul Kuis", titleController),
              _buildFormField("Kelas (otomatis)", kelasController,
                  readOnly: true),
              DropdownButtonFormField<String>(
                value: selectedMateriId,
                decoration: InputDecoration(
                  labelText: "Pilih Materi",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: materiList.map((materi) {
                  return DropdownMenuItem(
                    value: materi['id'].toString(),
                    child: Text(materi['judul']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedMateriId = val;
                  });
                },
                validator: (value) => value == null ? "Pilih materi" : null,
              ),
              SizedBox(height: 10),
              _buildFormField("Durasi (menit)", durationController,
                  keyboardType: TextInputType.number),
              _buildFormField("Deadline", deadlineController,
                  readOnly: true, onTap: _pickDeadline),
              SizedBox(height: 20),
              Text("Daftar Soal",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...questionControllers
                  .asMap()
                  .entries
                  .map((e) => _buildQuestionCard(e.key, e.value)),
              ElevatedButton(
                onPressed: _addQuestion,
                child: Text("Tambah Soal"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitQuiz,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 12)),
                child: Text("Simpan Perubahan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
