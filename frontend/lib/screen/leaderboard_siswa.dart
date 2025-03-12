import 'package:flutter/material.dart';
import '../models/leaderboard.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final String token; // Token autentikasi user

  const LeaderboardScreen({Key? key, required this.token}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Future<List<LeaderboardModel>>? leaderboardFuture;
  String kelas = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fungsi untuk mengambil data user yang sedang login
  void _loadUserData() async {
    try {
      final userData = await ApiService.fetchUserProfile(widget.token);
      setState(() {
        kelas = userData['kelas']; // Simpan kelas user yang login
        leaderboardFuture = ApiService.fetchLeaderboard(kelas, widget.token);
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() {
        leaderboardFuture = Future.error("Gagal memuat data pengguna");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: kelas.isEmpty
            ? const Text('Leaderboard')
            : Text('Leaderboard $kelas'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<LeaderboardModel>>(
        future: leaderboardFuture,
        builder: (context, snapshot) {
          print("Connection State: ${snapshot.connectionState}");
          print("Has Error: ${snapshot.hasError}");
          print("Has Data: ${snapshot.hasData}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("Error Details: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error.toString()}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data leaderboard"));
          }

          List<LeaderboardModel> leaderboard = snapshot.data!;

          return ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text("${index + 1}"),
                  ),
                  title: Text(leaderboard[index].name),
                  subtitle: Text("Kelas: ${leaderboard[index].kelas}"),
                  trailing: Text(
                    "${leaderboard[index].totalScore} Poin",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
