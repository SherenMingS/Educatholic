import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/leaderboard.dart';
import '../services/api_service.dart';
import 'dashboard_siswa.dart';
import 'materi_siswa.dart';
import 'profile_siswa.dart';
import 'quizlist_siswa.dart';

class LeaderboardScreen extends StatefulWidget {
  final String token;

  const LeaderboardScreen({Key? key, required this.token}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Future<List<LeaderboardModel>>? leaderboardFuture;
  String kelas = "";
  int _selectedIndex = 3; // Leaderboard tab

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final userData = await ApiService.fetchUserProfile(widget.token);
      setState(() {
        kelas = userData['kelas'] ?? "";
        leaderboardFuture = ApiService.fetchLeaderboard(kelas, widget.token);
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() {
        leaderboardFuture = Future.error("Gagal memuat data pengguna");
      });
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
          context,
          MaterialPageRoute(builder: (_) => MateriPage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentQuizListPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardSiswa()),
        );
        break;
      case 3:
        // Sudah di leaderboard, ga perlu kemana-mana
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage()),
        );
        break;
      default:
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

  Widget _buildLeaderboardCard(LeaderboardModel item, int rank) {
    // Setup warna khusus untuk Juara 1
    Color cardColor = rank == 1 ? Colors.amber.shade100 : Colors.white;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildLeading(rank),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text("Kelas: ${item.kelas}"),
        trailing: Text(
          "${item.totalScore ?? 0} Poin",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(int rank) {
    // Ganti icon untuk ranking 1-3
    switch (rank) {
      case 1:
        return const Icon(Icons.emoji_events,
            color: Colors.amber, size: 40); // Trophy Emas
      case 2:
        return const Icon(Icons.emoji_events,
            color: Colors.grey, size: 35); // Trophy Silver
      case 3:
        return const Icon(Icons.emoji_events,
            color: Colors.brown, size: 30); // Trophy Bronze
      default:
        return CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            "$rank",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
        kelas.isNotEmpty ? 'Leaderboard $kelas' : 'Leaderboard',
        style: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<LeaderboardModel>>(
        future: leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada data leaderboard",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          List<LeaderboardModel> leaderboard = snapshot.data!;
          leaderboard.sort((a, b) => b.totalScore
              .compareTo(a.totalScore)); // ✅ Sortir dari tinggi ke rendah

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final item = leaderboard[index];
              return _buildLeaderboardCard(item, index + 1);
            },
          );
        },
      ),
      bottomNavigationBar: _buildCurvedNavBar(),
    );
  }
}
