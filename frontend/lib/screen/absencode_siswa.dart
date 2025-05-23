import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../widgets/custom_appbar.dart';
import '../widgets/empty_bottombar.dart';

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

    if (_kodeController.text.trim().isEmpty) {
      setState(() {
        _loading = false;
        _message = "Kode tidak boleh kosong.";
      });
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('user_id');

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/attendance/check-code'),
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
        _message = "✅ Kode valid. Silakan klik Hadir.";
      } else if (data['status'] == 'already_absent') {
        _sudahAbsen = true;
        _message = "⚠️ Kamu sudah hadir untuk sesi ini.";
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
      Uri.parse('${ApiService.baseUrl}/attendance-records/absen'),
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
        content: Text("Kehadiran berhasil dicatat!"),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
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
      appBar: CustomPageAppBar(
        title: 'Input Kode Kehadiran',
        icon: Icons.verified_user,
      ),
      bottomNavigationBar: EmptyBottomBar(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Masukkan Kode Kehadiran",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 10),
              TextField(
                controller: _kodeController,
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : cekKode,
                  icon: Icon(Icons.check),
                  label: Text("Cek Kode"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: kirimAbsen,
                    icon: Icon(Icons.how_to_reg),
                    label: Text("Tandai Kehadiran Sekarang"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
