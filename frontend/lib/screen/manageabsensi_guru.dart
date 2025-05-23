import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/widgets/custom_appbar.dart';
import 'package:frontend/widgets/empty_bottombar.dart';

class ManageAbsensiPage extends StatefulWidget {
  final int sessionId;
  final String kelas;

  ManageAbsensiPage({required this.sessionId, required this.kelas});

  @override
  _ManageAbsensiPageState createState() => _ManageAbsensiPageState();
}

class _ManageAbsensiPageState extends State<ManageAbsensiPage> {
  List<dynamic> students = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(
          '${ApiService.baseUrl}/attendance-records/session/${widget.sessionId}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        students = data['data'];
        loading = false;
      });
    } else {
      print('Gagal load data siswa');
    }
  }

  Future<void> updateAttendance(int userId, String status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/attendance-records/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'session_id': widget.sessionId,
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      fetchStudents(); // Refresh setelah update
    } else {
      print('Gagal update absensi');
    }
  }

  void _showStatusDialog(BuildContext context, int userId) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Pilih Status Absensi'),
          children: ['hadir', 'izin', 'sakit', 'alfa'].map((status) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showConfirmDialog(context, userId, status);
              },
              child: Text(status[0].toUpperCase() + status.substring(1)),
            );
          }).toList(),
        );
      },
    );
  }

  void _showConfirmDialog(BuildContext context, int userId, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content:
              Text('Yakin ingin mengubah status siswa ini menjadi "$status"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                updateAttendance(userId, status);
              },
              child: Text('Ya, Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomPageAppBar(
        icon: Icons.check_circle,
        title: 'Absensi ${widget.kelas}',
      ),
      bottomNavigationBar: const EmptyBottomBar(),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(child: Text('Belum ada siswa.'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final userId = student['user_id'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(student['nama']),
                        subtitle: Text('Status: ${student['status']}'),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            if (userId != null) {
                              _showStatusDialog(context, userId);
                            } else {
                              print('User ID null');
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
