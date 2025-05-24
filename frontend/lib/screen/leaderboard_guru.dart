import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/leaderboard.dart';
import '../services/api_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/empty_bottombar.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

class TeacherLeaderboardScreen extends StatefulWidget {
  final String kelas;
  final String token;

  const TeacherLeaderboardScreen({
    Key? key,
    required this.kelas,
    required this.token,
  }) : super(key: key);

  @override
  _TeacherLeaderboardScreenState createState() =>
      _TeacherLeaderboardScreenState();
}

class _TeacherLeaderboardScreenState extends State<TeacherLeaderboardScreen> {
  late Future<List<LeaderboardModel>> leaderboardFuture;
  String selectedSemester = '1';

  @override
  void initState() {
    super.initState();
    leaderboardFuture =
        ApiService.getTeacherLeaderboard(widget.kelas, widget.token);
  }

  void _showExportBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Export Nilai ke Excel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedSemester,
                decoration: InputDecoration(
                  labelText: "Pilih Semester",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['1', '2'].map((sem) {
                  return DropdownMenuItem(
                    value: sem,
                    child: Text("Semester $sem"),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedSemester = val);
                },
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _exportToExcel(context),
                icon: Icon(Icons.download),
                label: Text('Export Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportToExcel(BuildContext context) async {
    final dio = Dio();
    final url =
        "${ApiService.modulUrl}/export-nilai?kelas=${widget.kelas}&semester=$selectedSemester";

    try {
      // 1. Minta izin
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Izin akses penyimpanan ditolak")),
        );
        return;
      }

      // 2. Simpan ke folder Download
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final fileName = "nilai_${widget.kelas}_semester_$selectedSemester.xlsx";
      final filePath = p.join(downloadsDir.path, fileName);

      final response = await dio.download(url, filePath);

      // 3. Tampilkan notifikasi berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Berhasil diunduh ke: $filePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Gagal mengunduh file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomPageAppBar(
        title: 'Nilai Kelas ${widget.kelas}',
        icon: Icons.leaderboard,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            tooltip: 'Export Nilai',
            onPressed: _showExportBottomSheet,
          )
        ],
      ),
      bottomNavigationBar: EmptyBottomBar(),
      body: FutureBuilder<List<LeaderboardModel>>(
        future: leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Tidak ada data leaderboard'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final student = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blueAccent,
                        child: Text("${index + 1}",
                            style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.name,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("Kelas: ${student.kelas}"),
                            if (student.averageScore != null)
                              Text(
                                  "Rata-rata: ${student.averageScore!.toStringAsFixed(1)}%",
                                  style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${student.totalScore} Poin",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
