import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import 'dashboard_guru.dart';

class StudentListPage extends StatefulWidget {
  final String kelas;
  final String token; // Tambahkan token untuk autentikasi API

  StudentListPage({required this.kelas, required this.token});

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  late Future<List<Student>> students;

  @override
  void initState() {
    super.initState();
    students = ApiService.getStudents(widget.kelas, widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelas ${widget.kelas}'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<List<Student>>(
        future: students,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Tidak ada siswa di kelas ini'));
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
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.black54),
                  ),
                  title: Text(student.name, style: TextStyle(fontSize: 16)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
