import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_siswa.dart';
import 'dashboard_guru.dart';
import 'register.dart';
import 'forgot_password.dart';
import 'pilihkelas_guru.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Cek apakah user sudah login sebelumnya
  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? role = prefs.getString('role');
    String? kelas =
        prefs.getString('kelas'); // Pastikan kelas siswa disimpan dengan benar

    print("Token: $token | Role: $role | Kelas: $kelas"); // Debugging

    if (token != null) {
      if (role == "siswa") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => DashboardSiswa()));
      } else if (role == "guru") {
        if (kelas == null) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => PilihKelasPage()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => DashboardGuru()));
        }
      }
    }
  }

  // Fungsi login
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email dan Password harus diisi!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://127.0.0.1:8000/api/login');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": _emailController.text,
        "password": _passwordController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      final role = data['role'];
      final kelas = data.containsKey('kelas') ? data['kelas'] : null;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', role);
      if (kelas != null) {
        await prefs.setString('kelas', kelas); // Simpan kelas siswa/guru
      }

      // ✅ Tambahkan baris ini untuk simpan user_id
      
      await prefs.setInt('user_id', data['user']['id']);
      print(">> USER ID DISIMPAN: ${data['user']['id']}");

      final checkPrefs = await SharedPreferences.getInstance();
      print(">> CEK USER ID DARI PREFS: ${checkPrefs.getInt('user_id')}");

      // Debugging
      print("Token yang disimpan: $token");
      print("Role yang disimpan: $role");
      print("Kelas yang disimpan: $kelas");
      print("User ID yang disimpan: ${data['user']['id']}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Berhasil!")),
      );

      // Arahkan berdasarkan role
      if (role == "siswa") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => DashboardSiswa()));
      } else if (role == "guru") {
        if (kelas == null) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => PilihKelasPage()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => DashboardGuru()));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Gagal! Cek email & password.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 50),
                SizedBox(width: 10),
                Text(
                  "EduCatholic",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email, color: Colors.blue),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock, color: Colors.blue),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ForgotPasswordPage()),
                  );
                },
                child: Text("Lupa Password?",
                    style: TextStyle(color: Colors.blue)),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text("Login", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 15),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Belum punya akun?",
                    style: TextStyle(color: Colors.black)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  child: Text("Register",
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
