import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_siswa.dart';
import 'dashboard_guru.dart';
import 'register.dart';
import 'forgot_password.dart';

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

  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? role = prefs.getString('role');

    if (token != null) {
      if (role == "siswa") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => DashboardSiswa()));
      } else if (role == "guru") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => DashboardGuru()));
      }
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email dan Password harus diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": _emailController.text,
        "password": _passwordController.text,
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      final role = data['role'];
      final kelas = data['kelas'];
      final userId = data['user']['id'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', role);
      await prefs.setInt('user_id', userId);

      if (role == 'siswa') {
        await prefs.setString('kelas', kelas);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => DashboardSiswa()));
      } else if (role == 'guru') {
        await prefs.setString('kelas_guru', kelas);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => DashboardGuru()));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Berhasil!")),
      );
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
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ForgotPasswordPage()));
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
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Belum punya akun?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => RegisterPage()));
                  },
                  child: Text("Register",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
