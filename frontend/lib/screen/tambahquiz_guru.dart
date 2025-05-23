// Versi lengkap AddQuizPage dengan input KKM & Max Attempts

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/empty_bottombar.dart';

class AddQuizPage extends StatefulWidget {
  @override
  _AddQuizPageState createState() => _AddQuizPageState();
}

class _AddQuizPageState extends State<AddQuizPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController deadlineController = TextEditingController();
  TextEditingController kkmController = TextEditingController(text: "75");
  TextEditingController attemptController = TextEditingController(text: "2");
  String? selectedClass;
  String? token;
  DateTime? selectedDeadline;
  List<Map<String, dynamic>> questionControllers = [];
  List<Map<String, dynamic>> materiList = [];
  String? selectedMateriId;

  @override
  void initState() {
    super.initState();
    _loadTokenAndClass();
    _addQuestion();
  }

  Future<void> _loadTokenAndClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    selectedClass = prefs.getString('kelas_guru');
    await _loadMateriList();
    setState(() {});
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

  void _addQuestion() {
    setState(() {
      questionControllers.add({
        "question": TextEditingController(),
        "option_1": TextEditingController(),
        "option_2": TextEditingController(),
        "option_3": TextEditingController(),
        "option_4": TextEditingController(),
        "correct_answer": TextEditingController(text: "A"),
        "imageUrl": null,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      questionControllers.removeAt(index);
    });
  }

  Future<String?> _uploadImageToServer(XFile pickedFile) async {
    try {
      http.MultipartFile multipartFile;
      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        multipartFile = http.MultipartFile.fromBytes('image', bytes,
            filename: pickedFile.name);
      } else {
        multipartFile =
            await http.MultipartFile.fromPath('image', pickedFile.path);
      }
      var request = http.MultipartRequest(
          'POST', Uri.parse('${ApiService.baseUrl}/upload-question-image'));
      request.files.add(multipartFile);
      request.headers['Authorization'] = 'Bearer $token';
      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody.body);
        return data['url'];
      } else {
        throw Exception("Upload gagal: ${responseBody.body}");
      }
    } catch (e) {
      print("❌ Upload gagal: $e");
    }
    return null;
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final uploadedUrl = await _uploadImageToServer(pickedFile);
      if (uploadedUrl != null) {
        setState(() {
          questionControllers[index]['imageUrl'] = uploadedUrl;
        });
      }
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
        final dt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute);
        setState(() {
          selectedDeadline = dt;
          deadlineController.text =
              DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
        });
      }
    }
  }

  Future<void> _submitQuiz() async {
    if (!_formKey.currentState!.validate() ||
        token == null ||
        selectedClass == null) return;
    if (questionControllers.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Minimal 1 soal harus ada!")));
      return;
    }
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('${ApiService.baseUrl}/quizzes'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = titleController.text;
      request.fields['kelas'] = selectedClass!;
      request.fields['materi_id'] = selectedMateriId!;
      request.fields['duration'] =
          (int.tryParse(durationController.text) ?? 30).toString();
      if (deadlineController.text.isNotEmpty) {
        request.fields['deadline'] = deadlineController.text;
      }
      request.fields['kkm'] = kkmController.text;
      request.fields['max_attempts'] = attemptController.text;

      for (int i = 0; i < questionControllers.length; i++) {
        final q = questionControllers[i];
        final prefix = 'questions[$i]';
        request.fields['$prefix[question]'] = q["question"].text;
        request.fields['$prefix[option_1]'] = q["option_1"].text;
        request.fields['$prefix[option_2]'] = q["option_2"].text;
        request.fields['$prefix[option_3]'] = q["option_3"].text;
        request.fields['$prefix[option_4]'] = q["option_4"].text;
        request.fields['$prefix[correct_answer]'] = q["correct_answer"].text;
        request.fields['$prefix[score]'] =
            (100 / questionControllers.length).toStringAsFixed(2);
        if (q["imageUrl"] != null) {
          request.fields['$prefix[image]'] = q["imageUrl"];
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Quiz berhasil dibuat")));
        Navigator.pop(context, true);
      } else {
        throw Exception("Gagal: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal membuat quiz: $e")));
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

  Widget _buildQuestionCard(int index, Map<String, dynamic> q) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFormField("Pertanyaan", q["question"]),
            _buildFormField("Opsi A", q["option_1"]),
            _buildFormField("Opsi B", q["option_2"]),
            _buildFormField("Opsi C", q["option_3"]),
            _buildFormField("Opsi D", q["option_4"]),
            DropdownButtonFormField<String>(
              value: q["correct_answer"].text,
              decoration: InputDecoration(
                labelText: "Jawaban Benar",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ["A", "B", "C", "D"]
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => q["correct_answer"].text = val!),
            ),
            SizedBox(height: 10),
            Row(children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(index),
                icon: Icon(Icons.image),
                label: Text("Upload Gambar"),
              ),
              SizedBox(width: 10),
              if (q['imageUrl'] != null)
                Image.network('${ApiService.modulUrl}/storage/' + q['imageUrl'],
                    width: 100, height: 100, fit: BoxFit.cover)
            ]),
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
      appBar: CustomPageAppBar(title: 'Tambah Kuis', icon: Icons.quiz),
      bottomNavigationBar: EmptyBottomBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildFormField("Judul Kuis", titleController),
              _buildFormField(
                  "Kelas", TextEditingController(text: selectedClass ?? ""),
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
                onChanged: (val) => setState(() => selectedMateriId = val),
                validator: (val) => val == null ? "Pilih materi" : null,
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
              Text("Soal Kuis",
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
                child: Text("Simpan Kuis"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
