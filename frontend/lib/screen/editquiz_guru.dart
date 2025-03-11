import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/quiz.dart';

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
  String? selectedClass;
  String? token;
  DateTime? selectedDeadline;
  List<Map<String, dynamic>> questions = [];

  final List<String> classList = ['7A', '7B', '8A', '8B', '9A', '9B'];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.quiz.title);
    durationController =
        TextEditingController(text: widget.quiz.duration.toString());
    deadlineController =
        TextEditingController(text: widget.quiz.deadline ?? '');
    selectedClass = widget.quiz.kelas;
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
    _loadQuestions(); // Panggil setelah token tersedia
  }

  Future<void> _loadQuestions() async {
    if (token == null) return;

    try {
      final quizDetail = await ApiService.getQuizDetail(widget.quiz.id, token!);

      setState(() {
        questions = quizDetail.questions
            .map((q) => {
                  "id": q.id,
                  "question": q.question,
                  "option_1": q.option1,
                  "option_2": q.option2,
                  "option_3": q.option3,
                  "option_4": q.option4,
                  "correct_answer": q.correctAnswer,
                })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat soal: $e")),
      );
    }
  }

  Future<void> _submitQuiz() async {
    if (_formKey.currentState!.validate() && token != null) {
      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Minimal 1 soal harus ada!")),
        );
        return;
      }

      // 🔥 Hitung skor setiap soal agar total tetap 100
      double scorePerQuestion = 100 / questions.length;
      for (var q in questions) {
        q["score"] =
            scorePerQuestion.toStringAsFixed(2); // Pastikan skor dibagi rata
      }

      Map<String, dynamic> quizData = {
        "title": titleController.text,
        "kelas": selectedClass,
        "duration": int.tryParse(durationController.text) ?? 30,
        "deadline":
            deadlineController.text.isNotEmpty ? deadlineController.text : null,
        "questions": questions,
      };

      try {
        // 🔥 Pastikan Flutter menggunakan UPDATE, bukan CREATE
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
  }

  void _addQuestion() {
    setState(() {
      questions = List.from(questions)
        ..add({
          "id": null, // NULL karena ini soal baru
          "question": "",
          "option_1": "",
          "option_2": "",
          "option_3": "",
          "option_4": "",
          "correct_answer": "A",
        });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      questions.removeAt(index);
    });
  }

  // 🕒 Fungsi untuk memilih tanggal dan waktu deadline
  void _pickDeadline() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Edit Kuis"), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Judul Kuis"),
                  validator: (value) =>
                      value!.isEmpty ? "Judul tidak boleh kosong" : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedClass,
                  decoration: const InputDecoration(labelText: "Pilih Kelas"),
                  items: classList.map((kelas) {
                    return DropdownMenuItem(value: kelas, child: Text(kelas));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedClass = value),
                  validator: (value) => value == null ? "Pilih kelas" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: durationController,
                  decoration:
                      const InputDecoration(labelText: "Durasi (menit)"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: deadlineController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Deadline",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _pickDeadline,
                ),
                const SizedBox(height: 20),
                const Text("Soal Kuis",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Column(
                  children: questions.asMap().entries.map((entry) {
                    int index = entry.key;
                    var question = entry.value;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              initialValue: question["question"],
                              decoration: const InputDecoration(
                                  labelText: "Pertanyaan"),
                              onChanged: (value) =>
                                  question["question"] = value,
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              initialValue: question["option_1"],
                              decoration:
                                  const InputDecoration(labelText: "Opsi A"),
                              onChanged: (value) =>
                                  question["option_1"] = value,
                            ),
                            TextFormField(
                              initialValue: question["option_2"],
                              decoration:
                                  const InputDecoration(labelText: "Opsi B"),
                              onChanged: (value) =>
                                  question["option_2"] = value,
                            ),
                            TextFormField(
                              initialValue: question["option_3"],
                              decoration:
                                  const InputDecoration(labelText: "Opsi C"),
                              onChanged: (value) =>
                                  question["option_3"] = value,
                            ),
                            TextFormField(
                              initialValue: question["option_4"],
                              decoration:
                                  const InputDecoration(labelText: "Opsi D"),
                              onChanged: (value) =>
                                  question["option_4"] = value,
                            ),
                            const SizedBox(height: 5),
                            DropdownButtonFormField(
                              value: question["correct_answer"],
                              decoration: const InputDecoration(
                                  labelText: "Jawaban Benar"),
                              items: ["A", "B", "C", "D"].map((opt) {
                                return DropdownMenuItem(
                                    value: opt, child: Text(opt));
                              }).toList(),
                              onChanged: (value) => setState(() {
                                question["correct_answer"] = value;
                              }),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => _removeQuestion(index),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text("Hapus Soal"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: _addQuestion, child: const Text("Tambah Soal")),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _submitQuiz,
                        child: const Text("Simpan Perubahan"))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
