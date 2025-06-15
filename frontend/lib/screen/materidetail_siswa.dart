import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../widgets/empty_bottombar.dart';
import 'package:url_launcher/url_launcher.dart';

void _openUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}

class MateriDetailPage extends StatefulWidget {
  final int materiId;
  final String materiJudul;

  MateriDetailPage({required this.materiId, required this.materiJudul});

  @override
  _MateriDetailPageState createState() => _MateriDetailPageState();
}

class _MateriDetailPageState extends State<MateriDetailPage> {
  Map<String, dynamic>? materiDetail;
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchMateri();
  }

  Future<void> _loadTokenAndFetchMateri() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    if (token != null) {
      try {
        var data = await ApiService.getMateriDetail(token!, widget.materiId);
        setState(() {
          materiDetail = data;
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat materi: $e")),
        );
      }
    }
  }

  void _openModul(String filePath) {
    final url = '${ApiService.modulUrl}/storage/$filePath';
    if (kIsWeb) {
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _markAsRead() async {
    if (token == null) return;

    final success = await ApiService.markMateriAsRead(widget.materiId, token!);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Materi ditandai sebagai sudah dibaca")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan progress")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> poinPoinList = [];
    if (materiDetail != null && materiDetail!['poin_poin'] != null) {
      poinPoinList = List<String>.from(materiDetail!['poin_poin']);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        automaticallyImplyLeading: false, // Supaya kita pakai custom leading
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.arrow_back, color: Colors.blue),
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.book, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.materiJudul,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // ✅ teks jadi putih
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: EmptyBottomBar(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : materiDetail == null
              ? Center(child: Text("Materi tidak ditemukan"))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/katolik.png',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 16),
                      Text(
                        materiDetail!['judul'],
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      if (poinPoinList.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Poin-Poin Materi:",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: poinPoinList.map((poin) {
                                return ElevatedButton(
                                  onPressed: () {},
                                  child: Text(poin),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      SizedBox(height: 16),
                      if (materiDetail!['ayat'] != null &&
                          materiDetail!['isi_ayat'] != null)
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                materiDetail!['ayat'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                materiDetail!['isi_ayat'],
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      if (materiDetail!['file'] != null &&
                          materiDetail!['file'].toString().isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16),
                            Text(
                              "Modul Materi:",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                _openModul(materiDetail!['file']);
                              },
                              icon: Icon(Icons.open_in_new),
                              label: Text("Lihat Modul"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 16),
                      Text(
                        materiDetail!['deskripsi'] ?? "Tidak ada deskripsi",
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(Icons.check_circle_outline),
                        label: Text("Saya sudah baca"),
                        onPressed: _markAsRead,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
