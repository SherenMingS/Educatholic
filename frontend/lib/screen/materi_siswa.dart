import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'package:frontend/screen/materi_siswa.dart';
import 'package:frontend/screen/quizlist_siswa.dart';
import 'package:frontend/screen/dashboard_siswa.dart';
import 'package:frontend/screen/leaderboard_siswa.dart';
import 'package:frontend/screen/profile_siswa.dart';
import 'package:frontend/services/api_service.dart';
import '../widgets/custom_appbar.dart';
import 'materidetail_siswa.dart';

class MateriPage extends StatefulWidget {
  @override
  _MateriPageState createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage> {
  List<dynamic> materiList = [];
  String? token;
  String? kelas;
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchMateri();
  }

  Future<void> _loadTokenAndFetchMateri() async {
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
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil data kelas siswa")),
      );
    }
  }

  Future<void> _fetchMateri(String kelas) async {
    try {
      final materiListData = await ApiService.getMateri(token!, kelas);
      setState(() {
        materiList = materiListData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat materi: $e")),
      );
    }
  }

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MateriPage()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentQuizListPage()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardSiswa()));
        break;
      case 3:
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');
        if (token != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(token: token)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token tidak ditemukan')),
          );
        }
        break;
      case 4:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfilePage()));
        break;
    }
  }

  Widget _buildCurvedNavBar() {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: Colors.blue,
      height: 70,
      index: _selectedIndex,
      animationDuration: const Duration(milliseconds: 300),
      items: [
        Icon(Icons.menu_book, size: 28, color: _selectedIndex == 0 ? Colors.yellow : Colors.white),
        Icon(Icons.assignment, size: 28, color: _selectedIndex == 1 ? Colors.yellow : Colors.white),
        Icon(Icons.home, size: 28, color: _selectedIndex == 2 ? Colors.yellow : Colors.white),
        Icon(Icons.emoji_events, size: 28, color: _selectedIndex == 3 ? Colors.yellow : Colors.white),
        Icon(Icons.person, size: 28, color: _selectedIndex == 4 ? Colors.yellow : Colors.white),
      ],
      onTap: _onItemTapped,
    );
  }

  Widget _buildMateriList() {
    if (isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => _buildShimmerCard(),
      );
    } else if (materiList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox, size: 80, color: Colors.blueGrey),
            SizedBox(height: 10),
            Text("Tidak ada materi ditemukan", style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
          ],
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: materiList.length,
        itemBuilder: (context, index) {
          var materi = materiList[index];
          return _buildMateriCard(materi);
        },
      );
    }
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.white,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(height: 80, width: double.infinity),
      ),
    );
  }

  Widget _buildMateriCard(dynamic materi) {
    final bool isTayang = materi['status'] == 'tayang';

    return GestureDetector(
      onTap: isTayang
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MateriDetailPage(
                    materiId: materi['id'],
                    materiJudul: materi['judul'],
                  ),
                ),
              );
            }
          : null,
      child: Opacity(
        opacity: isTayang ? 1.0 : 0.5,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isTayang ? Colors.blue : Colors.orange, width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isTayang ? Colors.blue : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.menu_book, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        materi["judul"],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isTayang ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isTayang ? "✅ Sudah Tayang" : "🕓 Belum Tayang",
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Tayang: ${materi['tanggal_tayang']}",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _refreshMateri() {
    if (kelas != null) {
      setState(() => isLoading = true);
      _fetchMateri(kelas!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomPageAppBar(
        title: 'Materi Kelas ${kelas ?? ''}',
        icon: Icons.menu_book,
        onBack: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardSiswa()));
        },
      ),
      body: _buildMateriList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _refreshMateri,
        child: const Icon(Icons.refresh),
      ),
      bottomNavigationBar: _buildCurvedNavBar(),
    );
  }
}
