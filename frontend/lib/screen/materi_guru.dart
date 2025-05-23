import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/widgets/custom_appbar.dart';
import 'package:frontend/widgets/empty_bottombar.dart';

class KelolaMateriPage extends StatefulWidget {
  @override
  _KelolaMateriPageState createState() => _KelolaMateriPageState();
}

class _KelolaMateriPageState extends State<KelolaMateriPage> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _kelasController = TextEditingController();
  final _poinController = TextEditingController();
  final _ayatController = TextEditingController();
  final _isiAyatController = TextEditingController();
  final _tanggalController = TextEditingController();

  List<dynamic> materiList = [];
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  String? selectedBook;
  int? selectedChapter;
  int? selectedVerse;

  List<String> books = [];
  List<int> chapters = [];
  List<int> verses = [];

  @override
  void initState() {
    super.initState();
    _getKelasAktif();
    fetchBooks();
  }

  Future<void> _getKelasAktif() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? kelasAktif = prefs.getString('kelas_guru');
    if (kelasAktif != null) {
      setState(() {
        _kelasController.text = kelasAktif;
      });
    }
  }

  Future<void> fetchBooks() async {
    final res =
        await http.get(Uri.parse('${ApiService.baseUrl}/bible/books'));
    if (res.statusCode == 200) {
      setState(() {
        books = List<String>.from(jsonDecode(res.body));
      });
    }
  }

  Future<void> fetchChapters(String book) async {
    final res = await http
        .get(Uri.parse('${ApiService.baseUrl}/bible/chapters?book=$book'));
    if (res.statusCode == 200) {
      setState(() {
        chapters = List<int>.from(jsonDecode(res.body));
      });
    }
  }

  Future<void> fetchVerses(String book, int chapter) async {
    final res = await http.get(Uri.parse(
        '${ApiService.baseUrl}/bible/verses?book=$book&chapter=$chapter'));
    if (res.statusCode == 200) {
      setState(() {
        verses = List<int>.from(jsonDecode(res.body));
      });
    }
  }

  Future<void> fetchIsiAyat() async {
    final res = await http.get(Uri.parse(
        '${ApiService.baseUrl}/bible/lookup?book=$selectedBook&chapter=$selectedChapter&verse=$selectedVerse'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _ayatController.text = data['ayat'];
        _isiAyatController.text = data['isi_ayat'];
      });
    }
  }

  

  Future<void> _fetchMateri() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? kelas = prefs.getString('kelas_guru');
    String? token = prefs.getString('token');

    if (kelas == null || token == null) {
      print("❌ Token atau kelas tidak ditemukan di SharedPreferences");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/materi?kelas=$kelas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("🔍 Status Code: ${response.statusCode}");
      print("🔍 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          materiList = json['materi'];
        });
      } else {
        print("❌ Gagal mengambil materi: ${response.body}");
      }
    } catch (e) {
      print("❌ Error saat fetch materi: $e");
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        _selectedFileBytes = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadMateri() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/materi'),
      );
      request.fields['judul'] = _judulController.text;
      request.fields['deskripsi'] = _deskripsiController.text;
      request.fields['kelas'] = _kelasController.text;
      request.fields['poin_poin'] = _poinController.text;
      request.fields['ayat'] = _ayatController.text;
      request.fields['isi_ayat'] = _isiAyatController.text;
      request.fields['tanggal_tayang'] = _tanggalController.text;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (_selectedFileBytes != null && _selectedFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedFileBytes!,
            filename: _selectedFileName,
          ),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Materi berhasil diunggah!")),
        );
        Navigator.pop(
            context, true); // balik ke halaman sebelumnya dan trigger refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengunggah materi: $responseBody")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan saat mengunggah materi!")),
      );
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Widget _textFieldOutline(String label, TextEditingController controller,
      {bool isMultiline = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              maxLines: isMultiline ? 3 : 1,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomPageAppBar(icon: Icons.menu_book, title: 'Materi'),
      bottomNavigationBar: const EmptyBottomBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _textFieldOutline("Judul", _judulController),
            _textFieldOutline("Deskripsi", _deskripsiController,
                isMultiline: true),
            _textFieldOutline("Kelas", _kelasController, readOnly: true),
            _textFieldOutline("Poin-poin", _poinController),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Referensi Alkitab",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DropdownSearch<String>(
              items: books,
              selectedItem: selectedBook,
              popupProps: PopupProps.menu(showSearchBox: true),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                    labelText: "Pilih Kitab", border: OutlineInputBorder()),
              ),
              onChanged: (val) {
                setState(() {
                  selectedBook = val;
                  selectedChapter = null;
                  selectedVerse = null;
                  _ayatController.clear();
                  _isiAyatController.clear();
                  chapters.clear();
                  verses.clear();
                });
                if (val != null) fetchChapters(val);
              },
            ),
            if (selectedBook != null)
              DropdownButton<int>(
                isExpanded: true,
                hint: const Text("Pilih Pasal"),
                value: selectedChapter,
                items: chapters
                    .map((ch) =>
                        DropdownMenuItem(value: ch, child: Text("Pasal $ch")))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedChapter = val;
                    selectedVerse = null;
                    _ayatController.clear();
                    _isiAyatController.clear();
                    verses.clear();
                  });
                  fetchVerses(selectedBook!, val!);
                },
              ),
            if (selectedChapter != null)
              DropdownButton<int>(
                isExpanded: true,
                hint: const Text("Pilih Ayat"),
                value: selectedVerse,
                items: verses
                    .map((v) =>
                        DropdownMenuItem(value: v, child: Text("Ayat $v")))
                    .toList(),
                onChanged: (val) {
                  setState(() => selectedVerse = val);
                  fetchIsiAyat();
                },
              ),
            _textFieldOutline("Ayat", _ayatController),
            _textFieldOutline("Isi Ayat", _isiAyatController,
                isMultiline: true),
            _textFieldOutline(
                "File", TextEditingController(text: _selectedFileName ?? "")),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _pickFile,
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                child: const Text("Choose File",
                    style: TextStyle(color: Colors.black)),
              ),
            ),
            _textFieldOutline("Tayang", _tanggalController, readOnly: true),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDate,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadMateri,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                elevation: 4,
              ),
              child: const Text("Upload", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
