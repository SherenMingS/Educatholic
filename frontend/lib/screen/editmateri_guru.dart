import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditMateriPage extends StatefulWidget {
  final int id;
  final String? judul;
  final String? deskripsi;
  final String? kelas;
  final String? poinPoin;
  final String? ayat;
  final String? isiAyat;
  final String? tanggalTayang;

  EditMateriPage({
    required this.id,
    this.judul,
    this.deskripsi,
    this.kelas,
    this.poinPoin,
    this.ayat,
    this.isiAyat,
    this.tanggalTayang,
  });

  @override
  _EditMateriPageState createState() => _EditMateriPageState();
}

class _EditMateriPageState extends State<EditMateriPage> {
  late TextEditingController _judulController;
  late TextEditingController _deskripsiController;
  late TextEditingController _kelasController;
  late TextEditingController _poinController;
  late TextEditingController _ayatController;
  late TextEditingController _isiAyatController;
  late TextEditingController _tanggalTayangController;

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
    _judulController = TextEditingController(text: widget.judul ?? '');
    _deskripsiController = TextEditingController(text: widget.deskripsi ?? '');
    _kelasController = TextEditingController(text: widget.kelas ?? '');
    _poinController = TextEditingController(text: widget.poinPoin ?? '');
    _ayatController = TextEditingController(text: widget.ayat ?? '');
    _isiAyatController = TextEditingController(text: widget.isiAyat ?? '');
    _tanggalTayangController =
        TextEditingController(text: widget.tanggalTayang ?? '');

    fetchBooks();
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

  Future<void> _showConfirmationDialog() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Perubahan"),
          content: Text("Yakin ingin mengubah data ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Ya, Ubah"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _updateMateri();
    }
  }

  Future<void> _updateMateri() async {
    Map<String, String> fields = {
      'judul': _judulController.text,
      'deskripsi': _deskripsiController.text,
      'kelas': _kelasController.text,
      'poin_poin': _poinController.text,
      'ayat': _ayatController.text,
      'isi_ayat': _isiAyatController.text,
      'tanggal_tayang': _tanggalTayangController.text,
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      if (_selectedFileBytes != null) {
        // kirim multipart
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'http://127.0.0.1:8000/api/materi/update-file/${widget.id}'),
        );

        request.fields.addAll(fields);
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedFileBytes!,
          filename: _selectedFileName,
        ));

        var response = await request.send();
        final resBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Materi berhasil diperbarui (dengan file)")));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Gagal update dengan file")));
        }
      } else {
        // kirim PUT biasa
        final response = await http.put(
          Uri.parse('http://127.0.0.1:8000/api/materi/${widget.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(fields),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Materi berhasil diperbarui")));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Gagal update data")));
        }
      }
    } catch (e) {
      print("❌ Error saat update: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan saat update")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Materi"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("Judul Materi", _judulController),
              _buildTextField("Deskripsi", _deskripsiController),
              _buildTextField("Kelas", _kelasController),
              _buildTextField("Poin-poin", _poinController),
              Text("Referensi Alkitab",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                isExpanded: true,
                hint: Text("Pilih Kitab"),
                value: selectedBook,
                items: books
                    .map((book) =>
                        DropdownMenuItem(value: book, child: Text(book)))
                    .toList(),
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
                    if (val != null) fetchVerses(selectedBook!, val);
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
              _buildTextField("Tanggal Tayang", _tanggalTayangController),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  child: Text("Simpan Perubahan"),
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
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          maxLines: isMultiline ? 3 : 1,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
