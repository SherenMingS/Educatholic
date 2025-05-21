import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/widgets/custom_appbar.dart';
import 'package:frontend/widgets/empty_bottombar.dart';

import 'manageabsensi_guru.dart';

class ListAttendanceSessionsPage extends StatefulWidget {
  @override
  _ListAttendanceSessionsPageState createState() =>
      _ListAttendanceSessionsPageState();
}

class _ListAttendanceSessionsPageState
    extends State<ListAttendanceSessionsPage> {
  List<dynamic> sessions = [];
  bool loading = true;
  String? kelasAktif;

  @override
  void initState() {
    super.initState();
    fetchSessions();
  }

  Future<void> fetchSessions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    kelasAktif = prefs.getString('kelas_guru');

    if (kelasAktif == null) return;

    final response = await http.get(
      Uri.parse(
          'http://127.0.0.1:8000/api/attendance-sessions?kelas=$kelasAktif'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<dynamic> allSessions = data['data'];

      List<dynamic> filteredSessions = allSessions.where((session) {
        return session['kelas'].toString().trim().toUpperCase() ==
            kelasAktif!.trim().toUpperCase();
      }).toList();

      setState(() {
        sessions = filteredSessions;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          const CustomPageAppBar(icon: Icons.people_alt, title: 'Sesi Absensi'),
      bottomNavigationBar: const EmptyBottomBar(),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? Center(child: Text('Belum ada sesi absensi untuk kelas ini.'))
              : ListView.builder(
                  itemCount: sessions.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('Kode: ${session['code']}',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text('Kelas: ${session['kelas']}'),
                            Text('Tanggal: ${session['tanggal']}'),
                            Text(
                                'Jam: ${session['jam_mulai']} - ${session['jam_selesai']}'),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageAbsensiPage(
                                sessionId: session['id'],
                                kelas: session['kelas'],
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
