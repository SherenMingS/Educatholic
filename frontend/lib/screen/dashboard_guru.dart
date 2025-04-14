import 'package:flutter/material.dart';
import 'package:frontend/screen/leaderboard_guru.dart';
import 'package:frontend/screen/manageabsensi_guru.dart';
import 'package:frontend/screen/materilist_guru.dart';
import 'package:frontend/screen/profile_guru.dart'; // Import halaman profile
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/dashboard_controller.dart';
import 'materi_guru.dart';
import 'editmateri_guru.dart';
import 'pilihkelas_guru.dart';
import 'studentlist_guru.dart';
import 'quizlist_guru.dart';
import 'package:frontend/screen/listabsensi_guru.dart'; // Ensure this file contains the ListAbsensiGuruPage class
import 'package:frontend/screen/createabsensi_guru.dart';

class DashboardGuru extends StatefulWidget {
  @override
  _DashboardGuruState createState() => _DashboardGuruState();
}

class _DashboardGuruState extends State<DashboardGuru> {
  final DashboardController controller = Get.put(DashboardController());
  int _selectedIndex = 1; // Home sebagai default
  String? _kelasGuru;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? kelas = prefs.getString('kelas_guru');
    setState(() {
      _kelasGuru = kelas;
    });

    if (token != null) {
      controller.fetchDashboardGuru(token);
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // Kalau klik icon Profile
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileGuruPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _changeClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('kelas_guru');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PilihKelasPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAttendanceStats(),
                    const SizedBox(height: 20),
                    _buildManagementOptions(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar() {
    return Stack(
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.blue, size: 50),
          ),
        ),
        Positioned(
          top: 60,
          left: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selamat Datang",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Obx(() => Text(
                    controller.name.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
              SizedBox(height: 5),
              Text(
                "Kelas Aktif: ${_kelasGuru ?? 'Belum dipilih'}",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        Positioned(
          top: 70,
          right: 20,
          child: IconButton(
            icon: Icon(Icons.swap_horiz, color: Colors.white),
            tooltip: "Ganti Kelas",
            onPressed: _changeClass,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Statistik Kehadiran",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          _buildProgressBar("8A", 0.78),
          _buildProgressBar("8B", 0.90),
        ],
      ),
    );
  }

  Widget _buildManagementOptions(BuildContext context) {
    return Column(
      children: [
        _managementCard(Icons.qr_code, "Buat Sesi Absensi", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateAbsensiGuruPage()),
          );
        }),
        _managementCard(Icons.book, "Manage Materi", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MateriGuruPage()),
          );
        }),
        _managementCard(Icons.edit, "Manage Absensi", () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ListAttendanceSessionsPage()),
          );
        }),
        _managementCard(Icons.assignment, "Kelola Kuis", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QuizListPage()),
          );
        }),
        _managementCard(Icons.leaderboard, "Manage Leaderboard", () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? token = prefs.getString('token');
          String? kelas = prefs.getString('kelas_guru');

          if (kelas != null && token != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TeacherLeaderboardScreen(kelas: kelas, token: token),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Silakan pilih kelas terlebih dahulu")),
            );
          }
        }),
        _managementCard(Icons.people, "Manage Siswa", () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? token = prefs.getString('token');
          String? kelas = prefs.getString('kelas_guru');

          if (kelas != null && token != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    StudentListPage(kelas: kelas, token: token),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Silakan pilih kelas terlebih dahulu")),
            );
          }
        }),
      ],
    );
  }

  Widget _managementCard(IconData icon, String title, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: Colors.blue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book),
          label: "Manage Kelas",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    );
  }

  Widget _buildProgressBar(String title, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14)),
        SizedBox(height: 5),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.blue,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
