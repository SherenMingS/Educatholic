import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat materi: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Ambil poin-poin & pisahkan berdasarkan koma
    // ✅ Ambil poin-poin dari API dengan format yang sesuai
    List<String> poinPoinList = [];
    if (materiDetail != null && materiDetail!['poin_poin'] != null) {
      poinPoinList = List<String>.from(materiDetail!['poin_poin']);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(widget.materiJudul),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : materiDetail == null
              ? Center(child: Text("Materi tidak ditemukan"))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// **Gambar Materi (Jika Ada)**
                      Image.asset(
                        'assets/dbsiswa.png',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),

                      SizedBox(height: 16),

                      /// **Judul Materi**
                      Text(
                        materiDetail!['judul'],
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),

                      SizedBox(height: 8),

                      /// **Poin-Poin Materi (Jika Ada)**
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

                            /// **Tampilkan Sebagai Tombol atau Badge**
                            Wrap(
                              spacing: 8,
                              children: poinPoinList.map((poin) {
                                return ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Poin: $poin")),
                                    );
                                  },
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

                      /// **Ayat yang Perlu Direnungkan**
                      if (materiDetail!['ayat'] != null &&
                          materiDetail!['isi_ayat'] != null)
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
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

                      SizedBox(height: 16),

                      /// **Isi Materi**
                      Text(
                        materiDetail!['deskripsi'] ?? "Tidak ada deskripsi",
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
    );
  }
}
