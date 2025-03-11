import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screen/dashboard_siswa.dart';
import 'package:frontend/screen/profile_siswa.dart';
import 'materidetail_siswa.dart'; // ✅ Import Halaman Detail Materi
import 'package:frontend/services/api_service.dart';

class MateriPage extends StatefulWidget {
  @override
  _MateriPageState createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage> {
  List<dynamic> materiList = [];
  String? token;
  String? kelas;
  int _selectedIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndClassAndFetchMateri();
  }

  // ✅ Ambil token & kelas dari SharedPreferences lalu fetch materi
  Future<void> _loadTokenAndClassAndFetchMateri() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('token');
    String? savedClass = prefs.getString('kelas');

    if (savedToken != null && savedClass != null) {
      setState(() {
        token = savedToken;
        kelas = savedClass;
      });
      _fetchMateri(savedClass);
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil data kelas siswa")),
      );
    }
  }

  // ✅ Fetch data materi dari API berdasarkan kelas siswa
  Future<void> _fetchMateri(String kelas) async {
    setState(() {
      isLoading = true;
    });

    try {
      final materiListData = await ApiService.getMateri(token!, kelas);
      setState(() {
        materiList = materiListData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat materi untuk kelas $kelas: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// **AppBar**
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Icon(Icons.menu_book, color: Colors.white),
            SizedBox(width: 8),
            Text(
                "Materi Kelas ${kelas ?? ''}"), // ✅ Tampilkan kelas siswa di judul
          ],
        ),
      ),

      /// **Body (List Materi)**
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Loader saat loading
          : materiList.isEmpty
              ? Center(
                  child: Text(
                      "Tidak ada materi untuk kelas ini")) // Jika tidak ada materi
              : ListView.builder(
                  itemCount: materiList.length,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  itemBuilder: (context, index) {
                    var materi = materiList[index];

                    return GestureDetector(
                      onTap: () {
                        // ✅ Navigasi ke halaman detail materi saat diklik
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MateriDetailPage(
                              materiId: materi['id'],
                              materiJudul: materi['judul'],
                            ),
                          ),
                        );
                      },
                      child: Card(
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
                              /// **Gambar Placeholder**
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black, // Placeholder gambar
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              SizedBox(width: 14),

                              /// **Judul Materi & Progress Bar**
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
                                    SizedBox(height: 6),

                                    /// **Progress Bar**
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: LinearProgressIndicator(
                                        value: 0.3, // Progress sementara
                                        backgroundColor: Colors.black,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.yellow),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

      /// **Curved Bottom Navigation Bar**
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
          Icon(Icons.quiz,
              size: 28,
              color: _selectedIndex == 1 ? Colors.yellow : Colors.white),
          Icon(Icons.home,
              size: 28,
              color: _selectedIndex == 2 ? Colors.yellow : Colors.white),
          Icon(Icons.emoji_events,
              size: 28,
              color: _selectedIndex == 3 ? Colors.yellow : Colors.white),
          Icon(Icons.person,
              size: 28,
              color: _selectedIndex == 4 ? Colors.yellow : Colors.white),
        ],
        onTap: (index) {
          if (index != _selectedIndex) {
            setState(() {
              _selectedIndex = index;
            });

            switch (index) {
              case 0:
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => MateriPage()));
                break;
              case 2:
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => DashboardSiswa()));
                break;
              case 4:
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => ProfilePage()));
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
