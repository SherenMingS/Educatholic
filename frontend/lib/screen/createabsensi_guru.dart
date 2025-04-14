import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateAbsensiGuruPage extends StatefulWidget {
  @override
  _CreateAbsensiGuruPageState createState() => _CreateAbsensiGuruPageState();
}

class _CreateAbsensiGuruPageState extends State<CreateAbsensiGuruPage> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _loading = false;
  String? generatedCode; // Simpan kode yang berhasil dibuat

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _submitAbsensi() async {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lengkapi semua field terlebih dahulu!')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? kelasGuru = prefs.getString('kelas_guru');
    String? token = prefs.getString('token');

    if (kelasGuru == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kelas atau token tidak ditemukan')),
      );
      return;
    }

    String jamMulai =
        '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
    String jamSelesai =
        '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';

    setState(() => _loading = true);

    final response = await http.post(
      Uri.parse('http://localhost:8000/api/attendance-sessions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'kelas': kelasGuru,
        'tanggal': _selectedDate!.toIso8601String().substring(0, 10),
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      var data = jsonDecode(response.body);
      setState(() {
        generatedCode = data['data']['code'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sesi Absensi berhasil dibuat')),
      );
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat sesi absensi')),
      );
    }
  }

  void _showKodeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Kode Absensi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                generatedCode ?? '',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "Berikan kode ini ke siswa untuk absensi.",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {Color? color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buat Sesi Absensi'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildButton(
              _selectedDate == null
                  ? 'Pilih Tanggal'
                  : 'Tanggal: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
              _pickDate,
              color: Colors.blue.shade100,
            ),
            SizedBox(height: 10),
            _buildButton(
              _startTime == null
                  ? 'Pilih Jam Mulai'
                  : 'Jam Mulai: ${_startTime!.format(context)}',
              _pickStartTime,
              color: Colors.blue.shade100,
            ),
            SizedBox(height: 10),
            _buildButton(
              _endTime == null
                  ? 'Pilih Jam Selesai'
                  : 'Jam Selesai: ${_endTime!.format(context)}',
              _pickEndTime,
              color: Colors.blue.shade100,
            ),
            SizedBox(height: 30),
            _loading
                ? const CircularProgressIndicator()
                : _buildButton(
                    'Buat Absensi', _submitAbsensi,
                    color: Colors.black87
                        .withOpacity(0.8) // Set opacity to 80%
                        .withAlpha(255), // Set alpha to 255 (fully opaque)
                  ),
            SizedBox(height: 20),
            generatedCode != null
                ? _buildButton(
                    'Lihat Kode Absen',
                    _showKodeDialog,
                    color: Colors.blue.shade100,
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
