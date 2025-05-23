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
        icon: Icons.leaderboard,
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blueAccent,
                        child: Text("${index + 1}", style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("Kelas: ${student.kelas}"),
                            if (student.averageScore != null)
                              Text("Rata-rata: ${student.averageScore!.toStringAsFixed(1)}%",
                                  style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${student.totalScore} Poin",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      )
                    ],
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
