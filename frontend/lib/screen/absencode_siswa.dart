import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AbsenKodePage extends StatefulWidget {
  @override
  _AbsenKodePageState createState() => _AbsenKodePageState();
}

class _AbsenKodePageState extends State<AbsenKodePage> {
  final _kodeController = TextEditingController();
  bool _kodeValid = false;
  bool _sudahAbsen = false;
  String? _sessionId;
  String? _kelas;
  String? _message;
  bool _loading = false;

  Future<void> cekKode() async {
    setState(() {
      _loading = true;
      _kodeValid = false;
      _sudahAbsen = false;
      _message = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('user_id');
    print("User ID: $userId");

    final response = await http.post(
      Uri.parse('http://localhost:8000/api/attendance/check-code'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'code': _kodeController.text.trim(),
        'user_id': userId,
      }),
    );

    final data = jsonDecode(response.body);

    setState(() {
      _loading = false;
      if (data['status'] == 'valid') {
        _kodeValid = true;
        _sessionId = data['session_id'].toString();
        _kelas = data['kelas'];
        _message = "Kode valid. Silakan klik Absen.";
      } else if (data['status'] == 'already_absent') {
        _sudahAbsen = true;
        _message = "Kamu sudah absen untuk sesi ini.";
      } else {
        _message = data['message'];
      }
    });
  }

  Future<void> kirimAbsen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('user_id');

    final response = await http.post(
      Uri.parse('http://localhost:8000/api/attendance-records/absen'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'session_id': int.parse(_sessionId!),
        'user_id': userId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Absensi berhasil dicatat!"),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context); // kembali ke dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message']),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Input Kode Absensi")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _kodeController,
              decoration: InputDecoration(
                labelText: "Masukkan Kode Absensi",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : cekKode,
              icon: Icon(Icons.check),
              label: Text("Cek Kode"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _kodeValid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 20),
            if (_kodeValid && !_sudahAbsen)
              ElevatedButton.icon(
                onPressed: kirimAbsen,
                icon: Icon(Icons.how_to_reg),
                label: Text("Absen Sekarang"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
