import 'package:flutter/material.dart';


import 'quizlist_siswa.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../controllers/dashboard_controller.dart';
import 'materi_siswa.dart'; // Import halaman Materi
import 'profile_siswa.dart'; // Import halaman Profil

class DashboardSiswa extends StatefulWidget {
  @override
  _DashboardSiswaState createState() => _DashboardSiswaState();
}

class CustomAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _DashboardSiswaState extends State<DashboardSiswa> {
  int _selectedIndex = 2; // **Home sebagai default tab aktif**
  final DashboardController controller = Get.put(DashboardController());

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  void _checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      print("Token masih ada: $token");
    } else {
      print("Token sudah dihapus atau tidak ditemukan.");
    }
  }

  @override
  Widget build(BuildContext context) {
    _fetchData();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            top: 200,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBanner(),
                    const SizedBox(height: 20),
                    _buildStats(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildAppBar()),
          Positioned(
              top: 130,
              left: 20,
              right: 20,
              child: _buildFeatureButtons(context)),
        ],
      ),
      bottomNavigationBar: _buildCurvedNavBar(context),
    );
  }

  void _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      controller.fetchDashboard(token);
    }
  }

  Widget _buildAppBar() {
    return ClipPath(
      clipper: CustomAppBarClipper(),
      child: Container(
        width: double.infinity,
        height: 180,
        color: Colors.blue,
        padding: const EdgeInsets.only(top: 0, left: 20, right: 20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 25,
              child: Icon(Icons.person, color: Colors.blue, size: 35),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Halo,",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w400),
                ),
                Obx(() => Text(
                      controller.name.value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _featureButton(Icons.menu_book, "Materi", () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MateriPage()),
            );
          }),
          _featureButton(Icons.assignment, "Kuis", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StudentQuizListPage()),
            );
          }),
          _featureButton(Icons.emoji_events, "Leaderboard", () {}),
        ],
      ),
    );
  }

  Widget _featureButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.black),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/dbsiswa.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: 100,
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        _statCard(Icons.history, "Riwayat Aktivitas Anda"),
        _statCard(Icons.show_chart,
            "Rata-rata Skor Kuis ${controller.quizAverage.value}%"),
        Obx(() => _statCard(
            Icons.badge, "Badges Tercapai (${controller.badgesCount.value})")),
      ],
    );
  }

  Widget _statCard(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.blue.shade200, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurvedNavBar(BuildContext context) {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: Colors.blue,
      height: 70,
      index: _selectedIndex, // **Home sebagai default tab aktif**
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
    );
  }
}
