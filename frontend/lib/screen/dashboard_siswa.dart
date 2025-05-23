import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screen/ActivityLogPage_siswa.dart';
import 'package:frontend/screen/absencode_siswa.dart';
import 'package:frontend/screen/leaderboard_siswa.dart';
import 'quizlist_siswa.dart';
import 'materi_siswa.dart';
import 'profile_siswa.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:http/http.dart' as http;
import '../controllers/dashboard_controller.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/theme_switch.dart';

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
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _DashboardSiswaState extends State<DashboardSiswa> {
  int _selectedIndex = 2;
  final DashboardController controller = Get.put(DashboardController());
  int? userId;
  String? absensiStatus;
  String? absensiMessage;

  @override
  void initState() {
    super.initState();
    _checkToken();
    _fetchData();
    fetchAbsensiStatus();
  }

  Future<void> fetchAbsensiStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/student/attendance/status'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        absensiStatus = data['status'];
        absensiMessage = data['message'] ?? '';
      });
    } else {
      setState(() {
        absensiStatus = 'error';
        absensiMessage = 'Gagal mengambil status absensi';
      });
    }
  }

  void _checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? storedUserId = prefs.getInt('user_id');
    setState(() {
      userId = storedUserId;
    });
  }

  void _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      controller.fetchDashboard(token);
    }
  }

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => MateriPage()));
        break;
      case 1:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => StudentQuizListPage()));
        break;
      case 2:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => DashboardSiswa()));
        break;
      case 3:
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');
        if (token != null) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => LeaderboardScreen(token: token)));
        }
        break;
      case 4:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => ProfilePage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              top: 130, left: 20, right: 20, child: _buildFeatureButtons()),
        ],
      ),
      bottomNavigationBar: _buildCurvedNavBar(),
    );
  }

  Widget _buildAppBar() {
    return ClipPath(
      clipper: CustomAppBarClipper(),
      child: Container(
        width: double.infinity,
        height: 180,
        color: Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 25,
                  child: Icon(Icons.person,
                      color: Theme.of(context).primaryColor, size: 35),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Halo,",
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    Obx(() => Text(
                          controller.name.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                ),
              ],
            ),
            const ThemeSwitchButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _featureButton(Icons.menu_book, "Materi", () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => MateriPage()));
          }),
          _featureButton(Icons.assignment, "Kuis", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => StudentQuizListPage()));
          }),
          _featureButton(Icons.emoji_events, "Leaderboard", () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? token = prefs.getString('token');
            if (token != null) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LeaderboardScreen(token: token)));
            }
          }),
        ],
      ),
    );
  }

  Widget _featureButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 36, color: Theme.of(context).iconTheme.color),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset('assets/dbsiswa.png',
          fit: BoxFit.cover, width: double.infinity, height: 100),
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(Icons.qr_code),
            label: Text("Tandai Kehadiran"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => AbsenKodePage())),
          ),
        ),
        const SizedBox(height: 12),
        _absensiStatusCard(),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ActivityLogPage()));
          },
          child: _statCard(Icons.history, "Riwayat Aktivitas Anda"),
        ),
        Obx(() => _statCard(
              Icons.show_chart,
              controller.quizAverage.value == 0
                  ? "Rata-rata Skor Kuis sedang dimuat..."
                  : "Rata-rata Skor Kuis ${controller.quizAverage.value}%",
            )),
        Obx(() => GestureDetector(
              onTap: () => _showBadgeDialog(context),
              child: _statCard(Icons.badge,
                  "Badges Tercapai (${controller.badgesCount.value}) • Level: ${controller.badgeLevel.value}"),
            )),
      ],
    );
  }

  Widget _absensiStatusCard() {
    IconData icon;
    Color color;
    String text;

    switch (absensiStatus) {
      case 'hadir':
        icon = Icons.check_circle;
        color = Colors.green;
        text = 'Hadir';
        break;
      case 'belum':
        icon = Icons.warning;
        color = Colors.orange;
        text = 'Belum Absen';
        break;
      case 'not_available':
        icon = Icons.info;
        color = Colors.blueGrey;
        text = 'Belum Ada Sesi';
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
        text = 'Memuat...';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Status Kehadiran Hari Ini: $text",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgeDialog(BuildContext context) {
    final count = controller.badgesCount.value;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("🎖️ Peringkat Badge Kamu", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _badgeLevelItem(
                  "🥉", "Beginner", "Punya minimal 1 badge", count >= 1),
              _badgeLevelItem(
                  "🥈", "Pro Player", "Punya minimal 5 badge", count >= 5),
              _badgeLevelItem(
                  "🥇", "Dewa Kuis", "Punya minimal 10 badge", count >= 10),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("Tutup")),
          ],
        );
      },
    );
  }

  Widget _badgeLevelItem(
      String emoji, String title, String subtitle, bool unlocked) {
    return ListTile(
      leading: Text(emoji, style: TextStyle(fontSize: 26)),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: unlocked ? Colors.black : Colors.grey)),
      subtitle: Text(subtitle,
          style: TextStyle(
              color: unlocked ? Colors.black54 : Colors.grey,
              fontStyle: unlocked ? FontStyle.normal : FontStyle.italic)),
      trailing: Icon(unlocked ? Icons.verified : Icons.lock,
          color: unlocked ? Colors.green : Colors.grey),
    );
  }

  Widget _statCard(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildCurvedNavBar() {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: Theme.of(context).primaryColor,
      height: 70,
      index: _selectedIndex,
      animationDuration: const Duration(milliseconds: 300),
      items: [
        Icon(Icons.menu_book,
            size: 28,
            color: _selectedIndex == 0 ? Colors.yellow : Colors.white),
        Icon(Icons.assignment,
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
      onTap: _onItemTapped,
    );
  }
}
