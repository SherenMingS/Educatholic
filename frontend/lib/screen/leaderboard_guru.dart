import 'package:flutter/material.dart';
import '../models/leaderboard.dart';
import '../services/api_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/empty_bottombar.dart';

class TeacherLeaderboardScreen extends StatefulWidget {
  final String kelas;
  final String token;

  const TeacherLeaderboardScreen({
    Key? key,
    required this.kelas,
    required this.token,
  }) : super(key: key);

  @override
  _TeacherLeaderboardScreenState createState() =>
      _TeacherLeaderboardScreenState();
}

class _TeacherLeaderboardScreenState extends State<TeacherLeaderboardScreen> {
  late Future<List<LeaderboardModel>> leaderboardFuture;

  @override
  void initState() {
    super.initState();
    leaderboardFuture =
        ApiService.getTeacherLeaderboard(widget.kelas, widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomPageAppBar(
        title: 'Nilai Kelas ${widget.kelas}',
        icon: Icons.leaderboard, // Add an appropriate icon
      ),
      bottomNavigationBar: EmptyBottomBar(),
      body: FutureBuilder<List<LeaderboardModel>>(
        future: leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Tidak ada data leaderboard'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final student = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text("${index + 1}"),
                  ),
                  title: Text(student.name, style: TextStyle(fontSize: 16)),
                  subtitle: Text("Kelas: ${student.kelas}"),
                  trailing: Text(
                    "${student.totalScore} Poin",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
