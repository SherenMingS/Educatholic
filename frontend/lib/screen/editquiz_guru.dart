import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/quiz.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/empty_bottombar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

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
  late TextEditingController kkmController;
  late TextEditingController attemptController;
  DateTime? selectedDeadline;
  String? selectedSemester;
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
    kkmController =
        TextEditingController(text: widget.quiz.kkm?.toString() ?? '75');
    attemptController =
        TextEditingController(text: widget.quiz.maxAttempts?.toString() ?? '1');
    selectedMateriId = widget.quiz.materiId?.toString();
    selectedSemester = widget.quiz.semester ?? '1'; // ✅ set default semester
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Token tidak ditemukan. Silakan login ulang."),
      ));
      return;
    }

    await _loadMateriList();
    await _loadQuestions();
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
            "image_url": TextEditingController(text: q.image ?? ''),
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal memuat soal: $e")));
    }
  }

  Future<void> _uploadImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.modulUrl}/api/upload-question-image'),
    );
    request.files
        .add(await http.MultipartFile.fromPath('image', pickedFile.path));
    request.headers['Authorization'] = 'Bearer $token';

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final urlPath = responseBody.split('"url":"')[1].split('"')[0];
      setState(() {
        questionControllers[index]["image_url"]!.text = urlPath;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Upload gagal, kode: ${response.statusCode}")));
    }
  }

  void _hapusGambar(int index) {
    setState(() {
      questionControllers[index]["image_url"]!.text = '';
    });
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
        DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month,
            pickedDate.day, pickedTime.hour, pickedTime.minute);
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Minimal 1 soal harus ada!")));
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
        "image": q["image_url"]?.text,
        "score": scorePerQuestion.toStringAsFixed(2),
      };
    }).toList();

    Map<String, dynamic> quizData = {
      "title": titleController.text,
      "kelas": kelasController.text,
      "semester": selectedSemester, // ✅ tambahkan semester ke API
      "materi_id": selectedMateriId,
      "duration": int.tryParse(durationController.text) ?? 30,
      "deadline":
          deadlineController.text.isNotEmpty ? deadlineController.text : null,
      "kkm": int.tryParse(kkmController.text) ?? 75,
      "max_attempts": int.tryParse(attemptController.text) ?? 1,
      "questions": questions,
    };

    try {
      await ApiService.updateQuiz(widget.quiz.id, quizData, token!);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Quiz berhasil diperbarui")));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal memperbarui quiz: $e")));
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Tampilkan gambar jika image_url tersedia
            if (q["image_url"] != null && q["image_url"]!.text.isNotEmpty)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${ApiService.modulUrl}/storage/' + q["image_url"]!.text,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Text('❌ Gagal memuat gambar'),
                    ),
                  ),
                  SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => _hapusGambar(index),
                    icon: Icon(Icons.delete_forever, color: Colors.red),
                    label: Text("Hapus Gambar",
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),

            TextButton.icon(
              onPressed: () => _uploadImage(index),
              icon: Icon(Icons.image, color: Colors.blue),
              label:
                  Text("Upload Gambar", style: TextStyle(color: Colors.blue)),
            ),

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
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomPageAppBar(title: 'Edit Kuis', icon: Icons.edit),
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
              // ✅ Semester Dropdown
              DropdownButtonFormField<String>(
                value: selectedSemester,
                decoration: InputDecoration(
                  labelText: "Semester",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: ['1', '2'].map((sem) {
                  return DropdownMenuItem(
                      value: sem, child: Text("Semester $sem"));
                }).toList(),
                onChanged: (val) => setState(() => selectedSemester = val),
                validator: (value) =>
                    value == null ? "Semester harus dipilih" : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedMateriId,
                decoration: InputDecoration(
                  labelText: "Pilih Materi",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: materiList.map((materi) {
                  return DropdownMenuItem(
                    value: materi['id'].toString(),
                    child: Text(
                      materi['judul'],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedMateriId = val),
                validator: (value) => value == null ? "Pilih materi" : null,
              ),
              _buildFormField("Nilai KKM", kkmController,
                  keyboardType: TextInputType.number),
              _buildFormField("Max Attempts", attemptController,
                  keyboardType: TextInputType.number),
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
                  onPressed: _addQuestion, child: Text("Tambah Soal")),
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
