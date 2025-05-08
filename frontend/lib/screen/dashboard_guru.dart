import 'package:flutter/material.dart';
import 'package:frontend/screen/leaderboard_guru.dart';
import 'package:frontend/screen/manageabsensi_guru.dart';
import 'package:frontend/screen/materilist_guru.dart';
import 'package:frontend/screen/profile_guru.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/dashboard_controller.dart';
import 'materi_guru.dart';
import 'quizlist_guru.dart';
import 'studentlist_guru.dart';
import 'listabsensi_guru.dart';
import 'createabsensi_guru.dart';

class DashboardGuru extends StatefulWidget {
  @override
  _DashboardGuruState createState() => _DashboardGuruState();
}

class _DashboardGuruState extends State<DashboardGuru> {
  final DashboardController controller = Get.put(DashboardController());
  int _selectedIndex = 1;
  String? _kelasGuru;
  bool _dialogSudahDitampilkan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchData();
      if (!_dialogSudahDitampilkan &&
          (_kelasGuru == null ||
              _kelasGuru!.isEmpty ||
              _kelasGuru == 'Belum dipilih' ||
              _kelasGuru!.startsWith('['))) {
        _dialogSudahDitampilkan = true;
        await _showKelasDialog();
      }
    });
  }

  Future<void> _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? kelas = prefs.getString('kelas_guru');
    String? token = prefs.getString('token');

    if (kelas == null || kelas.isEmpty || kelas.startsWith('[')) {
      _kelasGuru = "Belum dipilih";
    } else {
      _kelasGuru = kelas;

      // ✅ Panggil ambil data sesi absensi terakhir
      controller.fetchLastAttendance(kelas);
    }

    setState(() {}); // Untuk update UI

    if (token != null) {
      controller.fetchDashboardGuru(token);
    }
  }

  Future<void> _showKelasDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Pilih Kelas"),
        content: Text("Silakan pilih kelas yang ingin Anda kelola:"),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setString('kelas_guru', '8A');
              setState(() {
                _kelasGuru = '8A';
              });
              controller.fetchLastAttendance('8A'); // ✅ ini auto-refresh!
              Navigator.pop(context);
            },
            child: Text("Kelas 8A"),
          ),
          TextButton(
            onPressed: () async {
              await prefs.setString('kelas_guru', '8B');
              setState(() {
                _kelasGuru = '8B';
              });
              controller.fetchLastAttendance('8B'); // ✅ refresh juga di sini
              Navigator.pop(context);
            },
            child: Text("Kelas 8B"),
          ),
        ],
      ),
    );
  }

  Future<void> _changeClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('kelas_guru');
    setState(() {
      _kelasGuru = "Belum dipilih";
    });
    await _showKelasDialog();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
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
              Text("Selamat Datang",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
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
                "Kelas Aktif: ${_formatKelasAktif(_kelasGuru)}",
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

  String _formatKelasAktif(String? kelas) {
    if (kelas == null ||
        kelas.isEmpty ||
        kelas == 'Belum dipilih' ||
        kelas.startsWith('[')) {
      return 'Belum dipilih';
    }
    return kelas;
  }

  Widget _buildAttendanceStats() {
    return Obx(() {
      final data = controller.lastAttendance.value;

      if (data == null) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text("Belum ada sesi absensi terbaru."),
        );
      }

      final hadir = data['hadir'] ?? 0;
      final total = data['total_siswa'] ?? 1;
      final double persen = (hadir / total).clamp(0.0, 1.0);

      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📊 Sesi Absensi Terakhir",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _infoBox("Kelas", data['kelas']),
                _infoBox("Kode", data['kode']),
                _infoBox("Tanggal", data['tanggal']),
                _infoBox(
                    "Jam", "${data['jam_mulai']} - ${data['jam_selesai']}"),
                _infoBox(
                    "Hadir", "${data['hadir']} / ${data['total_siswa']} siswa"),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: persen,
              backgroundColor: Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
          ],
        ),
      );
    });
  }

  Widget _infoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
          SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
          backgroundColor: Colors.blue.shade100,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
