import 'package:flutter/material.dart';
import 'package:frontend/screen/materilist_guru.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    Map<String, dynamic> updatedData = {};

    if (_judulController.text.isNotEmpty) {
      updatedData['judul'] = _judulController.text;
    }
    if (_deskripsiController.text.isNotEmpty) {
      updatedData['deskripsi'] = _deskripsiController.text;
    }
    if (_kelasController.text.isNotEmpty) {
      updatedData['kelas'] = _kelasController.text;
    }
    if (_poinController.text.isNotEmpty) {
      updatedData['poin_poin'] = _poinController.text;
    }
    if (_ayatController.text.isNotEmpty) {
      updatedData['ayat'] = _ayatController.text;
    }
    if (_isiAyatController.text.isNotEmpty) {
      updatedData['isi_ayat'] = _isiAyatController.text;
    }
    if (_tanggalTayangController.text.isNotEmpty) {
      updatedData['tanggal_tayang'] = _tanggalTayangController.text;
    }

    if (updatedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tidak ada perubahan yang dilakukan")),
      );
      return;
    }

    final response = await http.put(
      Uri.parse('http://127.0.0.1:8000/api/materi/${widget.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedData),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memperbarui data")),
      );
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
        child: Column(
          children: [
            TextField(
              controller: _judulController,
              decoration: InputDecoration(
                labelText: "Judul Materi",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _deskripsiController,
              decoration: InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _kelasController,
              decoration: InputDecoration(
                labelText: "Kelas",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _poinController,
              decoration: InputDecoration(
                labelText: "Poin-Poin",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _ayatController,
              decoration: InputDecoration(
                labelText: "Ayat",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _isiAyatController,
              decoration: InputDecoration(
                labelText: "Isi Ayat",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _tanggalTayangController,
              decoration: InputDecoration(
                labelText: "Tanggal Tayang",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showConfirmationDialog,
              child: Text("Simpan Perubahan"),
            ),
          ],
        ),
      ),
    );
  }
}
