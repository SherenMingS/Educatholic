import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivityLogPage extends StatefulWidget {
  @override
  _ActivityLogPageState createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  List<Map<String, dynamic>> activityLogs = [];
  bool isLoading = true;
  String token = ''; // Token untuk autentikasi

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  // Mengambil token dari SharedPreferences
  Future<void> _fetchToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? ''; // Ambil token yang disimpan
    });
    if (token.isNotEmpty) {
      // Jika token ditemukan, fetch activity logs
      _fetchActivityLogs();
    } else {
      // Jika token tidak ada, beri informasi atau arahkan ke login
      setState(() {
        isLoading = false;
      });
      print("Token tidak ditemukan.");
    }
  }

  // Fungsi untuk mengambil data aktivitas dari API
  Future<void> _fetchActivityLogs() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/activity-logs'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parsing data yang diterima dari API
        var data = jsonDecode(response.body)['data'];
        List<Map<String, dynamic>> logs = [];

        // Jika data adalah list, langsung masukkan data ke dalam list logs
        logs = List<Map<String, dynamic>>.from(data);

        setState(() {
          activityLogs = logs;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load activity logs');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching activity logs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Aktivitas"),
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Tampilkan progress jika loading
          : ListView.builder(
              itemCount: activityLogs.length,
              itemBuilder: (context, index) {
                var log = activityLogs[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(log['action']),
                    subtitle: Text(log['description']),
                    trailing: IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: () {
                        // Tindakan ketika item diklik
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Detail Aktivitas"),
                              content: Text(log['status']),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Tutup"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
