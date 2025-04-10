import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:frontend/screen/login.dart';
import 'package:frontend/screen/dashboard_siswa.dart';
import 'package:frontend/screen/quizlist_siswa.dart';
import 'package:frontend/screen/materi_siswa.dart';
import 'package:frontend/screen/leaderboard_siswa.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String error = '';
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('http://localhost:8000/api/student/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          profileData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Gagal memuat profil (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
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
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');
        if (token != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LeaderboardScreen(token: token)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token tidak ditemukan')),
          );
        }
        break;
      case 4:
        // Already on Profile
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

  Widget profileItem(IconData icon, String label, String value) {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor, // 🔥 Dynamic Card Color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget buildProfileCard() {
    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 15),
        Text(
          profileData?['nama'] ?? '',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 25),
        profileItem(Icons.email, 'Email', profileData?['email'] ?? ''),
        profileItem(Icons.school, 'Kelas', profileData?['kelas'] ?? ''),
        profileItem(Icons.perm_identity, 'ID Siswa',
            profileData?['id'].toString() ?? ''),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context)
          .scaffoldBackgroundColor, // 🔥 Dynamic Background Color
      appBar: AppBar(
        title: const Text("Profil Saya"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error.isNotEmpty
                      ? Center(child: Text(error))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(
                              left: 20.0, right: 20.0, bottom: 100.0),
                          physics: const BouncingScrollPhysics(),
                          child: buildProfileCard(),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCurvedNavBar(),
    );
  }
}
