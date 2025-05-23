import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/empty_bottombar.dart';

class ActivityLogPage extends StatefulWidget {
  @override
  _ActivityLogPageState createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  List<Map<String, dynamic>> activityLogs = [];
  bool isLoading = true;
  String token = '';

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  Future<void> _fetchToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
    });
    if (token.isNotEmpty) {
      _fetchActivityLogs();
    } else {
      setState(() => isLoading = false);
      print("Token tidak ditemukan.");
    }
  }

  Future<void> _fetchActivityLogs() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/activity-logs'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['data'];
        List<Map<String, dynamic>> logs = [];

        if (data is List) {
          logs = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          logs = data.values.map((e) => Map<String, dynamic>.from(e)).toList();
        }

        // Reverse agar yang terbaru di atas
        setState(() {
          activityLogs = logs.reversed.toList();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat riwayat aktivitas');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching activity logs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomPageAppBar(title: "Riwayat Aktivitas", icon: Icons.history),
      bottomNavigationBar: EmptyBottomBar(),
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : activityLogs.isEmpty
              ? Center(child: Text("Belum ada aktivitas."))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: activityLogs.length,
                  itemBuilder: (context, index) {
                    var log = activityLogs[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(log['action'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(log['description']),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Detail Aktivitas"),
                              content: Text(log['status']),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Tutup"),
                                )
                              ],
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
