import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_guru.dart';

class PilihKelasPage extends StatelessWidget {
  Future<void> _setKelas(BuildContext context, String kelas) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('kelas_guru', kelas);

    // Setelah memilih kelas, arahkan ke Dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardGuru()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pilih Kelas")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Pilih kelas yang ingin dikelola:",
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _setKelas(context, "8A"),
              child: Text("Kelas 8A"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _setKelas(context, "8B"),
              child: Text("Kelas 8B"),
            ),
          ],
        ),
      ),
    );
  }
}
