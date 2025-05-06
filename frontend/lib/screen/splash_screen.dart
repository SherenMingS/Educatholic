import 'package:flutter/material.dart';
import 'package:frontend/screen/login.dart';
import 'package:frontend/screen/dashboard_siswa.dart';
import 'package:frontend/screen/dashboard_guru.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateFromSplash();
  }

  Future<void> _navigateFromSplash() async {
    await Future.delayed(Duration(seconds: 2)); // ⏱️ Durasi splash
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? role = prefs.getString('role');

    if (token != null && role != null) {
      if (role == 'siswa') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => DashboardSiswa()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => DashboardGuru()));
      }
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // 💙 Ubah jadi biru
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 120), // Logo kamu
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white), // Loader putih
            ),
          ],
        ),
      ),
    );
  }
}
