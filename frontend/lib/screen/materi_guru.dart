import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KelolaMateriPage extends StatefulWidget {
  @override
  _KelolaMateriPageState createState() => _KelolaMateriPageState();
}

class _KelolaMateriPageState extends State<KelolaMateriPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();
  final TextEditingController _poinController = TextEditingController();
  final TextEditingController _ayatController = TextEditingController();
  final TextEditingController _isiAyatController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();

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
        await http.get(Uri.parse('http://127.0.0.1:8000/api/bible/books'));
    if (res.statusCode == 200) {
      setState(() {
        books = List<String>.from(jsonDecode(res.body));
      });
    }
  }

  Future<void> fetchChapters(String book) async {
    final res = await http
        .get(Uri.parse('http://127.0.0.1:8000/api/bible/chapters?book=$book'));
    if (res.statusCode == 200) {
      setState(() {
        chapters = List<int>.from(jsonDecode(res.body));
      });
    }
  }

  Future<void> fetchVerses(String book, int chapter) async {
    final res = await http.get(Uri.parse(
        'http://127.0.0.1:8000/api/bible/verses?book=$book&chapter=$chapter'));
    if (res.statusCode == 200) {
      setState(() {
        verses = List<int>.from(jsonDecode(res.body));
      });
    }
  }

  Future<void> fetchIsiAyat() async {
    final res = await http.get(Uri.parse(
        'http://127.0.0.1:8000/api/bible/lookup?book=$selectedBook&chapter=$selectedChapter&verse=$selectedVerse'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _ayatController.text = data['ayat'];
        _isiAyatController.text = data['isi_ayat'];
      });
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
    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silakan pilih file terlebih dahulu!")),
      );
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/materi'),
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

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedFileBytes!,
          filename: _selectedFileName,
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Materi berhasil diunggah!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengunggah materi.")),
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan saat mengunggah materi!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Materi", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("Judul", _judulController),
              _buildTextField("Deskripsi", _deskripsiController,
                  isMultiline: true),
              _buildReadOnlyField("Kelas", _kelasController),
              _buildTextField("Poin-poin", _poinController),
              SizedBox(height: 10),
              Text("Referensi Alkitab",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownSearch<String>(
                items: books,
                selectedItem: selectedBook,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Cari kitab...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Pilih Kitab",
                    border: OutlineInputBorder(),
                  ),
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
                  hint: Text("Pilih Pasal"),
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
                  hint: Text("Pilih Ayat"),
                  value: selectedVerse,
                  items: verses
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text("Ayat $v")))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedVerse = val;
                    });
                    fetchIsiAyat();
                  },
                ),
              _buildTextField("Ayat", _ayatController),
              _buildTextField("Isi Ayat", _isiAyatController,
                  isMultiline: true),
              SizedBox(height: 10),
              Text("File",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: _pickFile,
                child: Text(_selectedFileName ?? "Pilih File"),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
              ),
              SizedBox(height: 10),
              Text("Tanggal Tayang",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                controller: _tanggalController,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _uploadMateri,
                  child: Text("Upload", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isMultiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: isMultiline ? 3 : 1,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[200],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
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
}
