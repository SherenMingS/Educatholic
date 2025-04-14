import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'manageabsensi_guru.dart'; // Import halaman manage absensi

class ListAttendanceSessionsPage extends StatefulWidget {
  @override
  _ListAttendanceSessionsPageState createState() =>
      _ListAttendanceSessionsPageState();
}

class _ListAttendanceSessionsPageState
    extends State<ListAttendanceSessionsPage> {
  List<dynamic> sessions = [];
  bool loading = true;
  String? kelasAktif; // <- untuk simpan kelas aktif dari SharedPreferences

  @override
  void initState() {
    super.initState();
    fetchSessions();
  }

  Future<void> fetchSessions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    kelasAktif = prefs.getString('kelas_guru'); // <- Ambil kelas aktif

    print('Kelas Aktif: $kelasAktif'); // DEBUG lihat kelas aktif

    if (kelasAktif == null) {
      print('Kelas aktif tidak ditemukan.');
      return;
    }

    final response = await http.get(
      Uri.parse(
          'http://localhost:8000/api/attendance-sessions?kelas=$kelasAktif'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<dynamic> allSessions = data['data'];

      // FILTER sesi absensi berdasarkan kelas aktif
      List<dynamic> filteredSessions = allSessions.where((session) {
        // Bandingkan dengan aman
        return session['kelas'].toString().trim().toUpperCase() ==
            kelasAktif!.trim().toUpperCase();
      }).toList();

      setState(() {
        sessions = filteredSessions;
        loading = false;
      });
    } else {
      print('Gagal load sesi absensi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Sesi Absensi'),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? Center(child: Text('Belum ada sesi absensi untuk kelas ini.'))
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Kode: ${session['code']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kelas: ${session['kelas']}'),
                            Text('Tanggal: ${session['tanggal']}'),
                            Text(
                                'Jam: ${session['jam_mulai']} - ${session['jam_selesai']}'),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageAbsensiPage(
                                sessionId: session['id'],
                                kelas: session['kelas'], // Tetap bawa kelas
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
