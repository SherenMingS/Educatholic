import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screen/editmateri_guru.dart';
import 'package:frontend/screen/materi_guru.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/screen/dashboard_guru.dart';
import 'materi_guru.dart';
import 'editmateri_guru.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MateriGuruPage extends StatefulWidget {
  @override
  _MateriGuruPageState createState() => _MateriGuruPageState();
}

class _MateriGuruPageState extends State<MateriGuruPage> {
  List<dynamic> materiList = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchMateri();
  }

  Future<void> _fetchMateri() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? kelas = prefs.getString('kelas_guru'); // Ambil kelas aktif
    String? token = prefs.getString('token'); // Ambil token

    if (kelas == null || token == null) {
      print("❌ Token atau kelas tidak ditemukan di SharedPreferences");
      return;
    }

    print("✅ Mengambil materi untuk kelas: $kelas");
    print("✅ Token: $token");

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/materi?kelas=$kelas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      print("🔍 Status Code: ${response.statusCode}");
      print("🔍 Respons API: ${response.body}");

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          materiList = jsonResponse['materi'];
        });
        print("✅ Data berhasil dimuat, jumlah materi: ${materiList.length}");
      } else {
        print("❌ Gagal mengambil data: ${response.statusCode}");
        print("❌ Respons API: ${response.body}");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<void> _deleteMateri(int id) async {
    final response = await http.delete(
      Uri.parse('http://127.0.0.1:8000/api/materi/$id'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Materi berhasil dihapus")),
      );
      setState(() {
        _fetchMateri(); // Refresh daftar materi setelah penghapusan
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus materi")),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Hapus"),
          content: Text("Apakah Anda yakin ingin menghapus materi ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Batalkan hapus
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Lanjutkan hapus
              child: Text("Ya, Hapus"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteMateri(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Icon(Icons.menu_book, color: Colors.white),
            SizedBox(width: 8),
            Text("Kelola Materi"),
          ],
        ),
      ),
      body: materiList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: materiList.length,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              itemBuilder: (context, index) {
                var materi = materiList[index];

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue, width: 1),
                  ),
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                materi["judul"],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditMateriPage(
                                  id: materi["id"],
                                  judul: materi["judul"],
                                  deskripsi: materi["deskripsi"] ?? '',
                                  kelas: materi["kelas"] ?? '',
                                  poinPoin: materi["poin_poin"] ?? '',
                                  ayat: materi["ayat"] ?? '',
                                  isiAyat: materi["isi_ayat"] ?? '',
                                  tanggalTayang: materi["tanggal_tayang"] ?? '',
                                ),
                              ),
                            );

                            if (result == true) {
                              setState(() {
                                _fetchMateri(); // Panggil ulang data jika ada perubahan
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(materi["id"]);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KelolaMateriPage()),
          );
          // Navigasi ke halaman tambah materi
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.blue,
        height: 70,
        index: _selectedIndex,
        animationDuration: Duration(milliseconds: 300),
        items: [
          Icon(Icons.menu_book,
              size: 28,
              color: _selectedIndex == 0 ? Colors.yellow : Colors.white),
          Icon(Icons.home,
              size: 28,
              color: _selectedIndex == 1 ? Colors.yellow : Colors.white),
          Icon(Icons.person,
              size: 28,
              color: _selectedIndex == 2 ? Colors.yellow : Colors.white),
        ],
        onTap: (index) {
          if (index != _selectedIndex) {
            setState(() {
              _selectedIndex = index;
            });

            switch (index) {
              case 0:
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => MateriGuruPage()));
                break;
              case 1:
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => DashboardGuru()));
                break;
              default:
                break;
            }
          }
        },
      ),
    );
  }
}
