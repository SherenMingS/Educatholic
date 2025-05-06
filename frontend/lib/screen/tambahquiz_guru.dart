import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AddQuizPage extends StatefulWidget {
  @override
  _AddQuizPageState createState() => _AddQuizPageState();
}

class _AddQuizPageState extends State<AddQuizPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController deadlineController = TextEditingController();
  String? selectedClass;
  String? token;
  DateTime? selectedDeadline;
  List<Map<String, dynamic>> questions = [];

  List<Map<String, dynamic>> materiList = [];
  String? selectedMateriId;

  final List<String> classList = ['8A', '8B'];

  @override
  void initState() {
    super.initState();
    _loadTokenAndClass();
  }

  Future<void> _loadTokenAndClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    selectedClass = prefs.getString('kelas_guru');
    await _loadMateriList();
  }

  Future<void> _loadMateriList() async {
    if (token == null || selectedClass == null) return;

    try {
      final materiData = await ApiService.getMateri(token!, selectedClass!);
      setState(() {
        materiList = List<Map<String, dynamic>>.from(materiData);
      });
    } catch (e) {
      print("❌ Gagal mengambil materi: $e");
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

      double scorePerQuestion = 100 / questions.length;
      for (var q in questions) {
        q["score"] = scorePerQuestion.toStringAsFixed(2);
      }

      Map<String, dynamic> quizData = {
        "title": titleController.text,
        "kelas": selectedClass,
        "materi_id": selectedMateriId,
        "duration": int.tryParse(durationController.text) ?? 30,
        "deadline":
            deadlineController.text.isNotEmpty ? deadlineController.text : null,
        "questions": questions,
      };

      try {
        await ApiService.createQuiz(quizData, token!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Quiz berhasil dibuat")),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuat quiz: $e")),
        );
      }
    }
  }

  void _addQuestion() {
    setState(() {
      questions.add({
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
      appBar: AppBar(title: Text("Tambah Kuis"), backgroundColor: Colors.blue),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: "Judul Kuis"),
                  validator: (value) =>
                      value!.isEmpty ? "Judul tidak boleh kosong" : null,
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedClass,
                  decoration: InputDecoration(labelText: "Pilih Kelas"),
                  items: classList.map((kelas) {
                    return DropdownMenuItem(value: kelas, child: Text(kelas));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClass = value;
                      selectedMateriId = null;
                    });
                    _loadMateriList(); // refresh materi saat ganti kelas
                  },
                  validator: (value) => value == null ? "Pilih kelas" : null,
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedMateriId,
                  decoration:
                      InputDecoration(labelText: "Pilih Materi Terkait"),
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
                TextFormField(
                  controller: durationController,
                  decoration: InputDecoration(labelText: "Durasi (menit)"),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: deadlineController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Deadline",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _pickDeadline,
                ),
                SizedBox(height: 20),
                Text("Soal Kuis",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Column(
                  children: questions.asMap().entries.map((entry) {
                    int index = entry.key;
                    var question = entry.value;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      elevation: 3,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              initialValue: question["question"],
                              decoration:
                                  InputDecoration(labelText: "Pertanyaan"),
                              onChanged: (value) =>
                                  question["question"] = value,
                            ),
                            TextFormField(
                              initialValue: question["option_1"],
                              decoration: InputDecoration(labelText: "Opsi A"),
                              onChanged: (value) =>
                                  question["option_1"] = value,
                            ),
                            TextFormField(
                              initialValue: question["option_2"],
                              decoration: InputDecoration(labelText: "Opsi B"),
                              onChanged: (value) =>
                                  question["option_2"] = value,
                            ),
                            TextFormField(
                              initialValue: question["option_3"],
                              decoration: InputDecoration(labelText: "Opsi C"),
                              onChanged: (value) =>
                                  question["option_3"] = value,
                            ),
                            TextFormField(
                              initialValue: question["option_4"],
                              decoration: InputDecoration(labelText: "Opsi D"),
                              onChanged: (value) =>
                                  question["option_4"] = value,
                            ),
                            DropdownButtonFormField(
                              value: question["correct_answer"],
                              decoration:
                                  InputDecoration(labelText: "Jawaban Benar"),
                              items: ["A", "B", "C", "D"].map((opt) {
                                return DropdownMenuItem(
                                    value: opt, child: Text(opt));
                              }).toList(),
                              onChanged: (value) => setState(() {
                                question["correct_answer"] = value;
                              }),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => _removeQuestion(index),
                              child: Text("Hapus Soal"),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                    onPressed: _addQuestion, child: Text("Tambah Soal")),
                SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _submitQuiz, child: Text("Simpan Kuis"))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
