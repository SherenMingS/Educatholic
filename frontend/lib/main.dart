import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/login.dart';
import 'screen/dashboard_siswa.dart';
import 'screen/dashboard_guru.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? role = prefs.getString('role');

  runApp(MyApp(token: token, role: role));
}

class MyApp extends StatelessWidget {
  final String? token;
  final String? role;

  MyApp({this.token, this.role});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: token == null
          ? LoginScreen() // Jika belum login, tetap di halaman login
          : (role == "siswa" ? DashboardSiswa() : DashboardGuru()), // Arahkan ke dashboard sesuai role
    );
  }
}
