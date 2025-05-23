import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/widgets/custom_appbar.dart';
import 'package:frontend/widgets/empty_bottombar.dart';

class EditMateriPage extends StatefulWidget {
  final int id;
  final String? judul;
  final String? deskripsi;
  final String? kelas;
  final String? poinPoin;
  final String? ayat;
  final String? isiAyat;
  final String? tanggalTayang;
  final String? file;

  EditMateriPage({
    required this.id,
    this.judul,
    this.deskripsi,
    this.kelas,
    this.poinPoin,
    this.ayat,
    this.isiAyat,
    this.tanggalTayang,
    this.file,
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
  late TextEditingController _fileNameController;

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

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
    _fileNameController = TextEditingController(
      text: widget.file != null ? widget.file!.split('/').last : '',
    );
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
        _fileNameController.text = _selectedFileName!;
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(_tanggalTayangController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _tanggalTayangController.text =
            DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _updateMateri() async {
    final fields = {
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
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              '${ApiService.baseUrl}/materi/update-file/${widget.id}'),
        );

        request.fields.addAll(fields);
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedFileBytes!,
          filename: _selectedFileName,
        ));

        var response = await request.send();
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Materi berhasil diperbarui")));
          Navigator.pop(context, true);
        }
      } else {
        final response = await http.put(
          Uri.parse('${ApiService.baseUrl}/materi/${widget.id}'),
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
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan saat update")));
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
    final fileUrl = widget.file != null
        ? '${ApiService.modulUrl}/storage/${widget.file}'
        : null;

    return Scaffold(
      appBar:
          const CustomPageAppBar(icon: Icons.menu_book, title: 'Edit Materi'),
      bottomNavigationBar: const EmptyBottomBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _textFieldOutline("Judul", _judulController),
            _textFieldOutline("Deskripsi", _deskripsiController,
                isMultiline: true),
            _textFieldOutline("Kelas", _kelasController),
            _textFieldOutline("Poin-poin", _poinController),
            _textFieldOutline("Ayat", _ayatController),
            _textFieldOutline("Isi Ayat", _isiAyatController,
                isMultiline: true),
            _textFieldOutline("File", _fileNameController, readOnly: true),
            if (widget.file != null && widget.file!.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(fileUrl!)),
                  icon: Icon(Icons.visibility),
                  label: Text("Lihat File Lama"),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _pickFile,
                child: Text("Choose File"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            _textFieldOutline("Tayang", _tanggalTayangController,
                readOnly: true),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: _selectDate,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateMateri,
              child: Text("Simpan Perubahan", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
