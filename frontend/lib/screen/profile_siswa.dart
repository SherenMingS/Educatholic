import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screen/leaderboard_siswa.dart';
import 'package:frontend/screen/materi_siswa.dart';
import 'package:frontend/screen/quizlist_siswa.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart'; // For image picking
// To handle file names
import 'package:frontend/screen/login.dart'; // For Login Screen redirection
import 'package:frontend/screen/dashboard_siswa.dart'; // For dashboard redirection
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:http_parser/http_parser.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool isUploading = false;
  String error = '';
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      this.context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  // Image picker and upload function
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final fileBytes = await pickedFile.readAsBytes(); // Get image as byte array

    setState(() {
      isUploading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/user/update-photo'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // Adding the image as byte array with correct media type
    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      fileBytes,
      filename: 'profile_picture.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));

    var response = await request.send();

    if (!mounted) return;

    if (response.statusCode == 200) {
      // After upload, fetch the profile again to update the image URL
      await fetchProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diupdate!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal upload foto.')),
      );
    }

    setState(() {
      isUploading = false;
    });
  }

  // Fetch profile from backend
  Future<void> fetchProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/student/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('PROFILE DATA: $decoded'); // ⬅️ TAMBAHKAN INI

        setState(() {
          profileData = decoded;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Gagal memuat profil (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  // Handle the navigation to different pages (bottom navigation)
  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
            this.context, MaterialPageRoute(builder: (_) => MateriPage()));
        break;
      case 1:
        Navigator.pushReplacement(this.context,
            MaterialPageRoute(builder: (_) => StudentQuizListPage()));
        break;
      case 2:
        Navigator.pushReplacement(
            this.context, MaterialPageRoute(builder: (_) => DashboardSiswa()));
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
        // Stay on Profile
        break;
    }
  }

  // Curved navigation bar
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

  // Profile item in the list
  Widget profileItem(IconData icon, String label, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(value),
      ),
    );
  }

  // Profile card display
  Widget buildProfileCard() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profileData?['photo'] != null
                  ? NetworkImage(
                      'http://192.168.18.85:8000/${profileData!['photo']}?v=${DateTime.now().millisecondsSinceEpoch}')
                  : null,
              backgroundColor: Colors.blue,
              child: profileData?['photo'] == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: isUploading ? null : _pickAndUploadImage,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.camera_alt, size: 20),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 15),
        Text(
          profileData?['nama'] ?? '',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 25),
        profileItem(Icons.email, 'Email', profileData?['email'] ?? ''),
        profileItem(Icons.school, 'Kelas', profileData?['kelas'] ?? ''),
        profileItem(
            Icons.transgender, 'Jenis Kelamin', profileData?['gender'] ?? '-'),
        profileItem(Icons.domain, 'Sekolah',
            'SMP Santo Hilarius'), // ✅ Tambah hardcoded
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _logout(),
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profil Saya"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty
                ? Center(child: Text(error))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: buildProfileCard(),
                  ),
      ),
      bottomNavigationBar: _buildCurvedNavBar(),
    );
  }
}
