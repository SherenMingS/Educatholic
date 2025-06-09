import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screen/materilist_guru.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/screen/dashboard_guru.dart';
import 'package:frontend/screen/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class ProfileGuruPage extends StatefulWidget {
  const ProfileGuruPage({Key? key}) : super(key: key);

  @override
  State<ProfileGuruPage> createState() => _ProfileGuruPageState();
}

class _ProfileGuruPageState extends State<ProfileGuruPage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool isUploading = false;
  String error = '';
  int _selectedIndex = 2;

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
        Uri.parse('${ApiService.baseUrl}/teacher/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
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

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final fileBytes = await pickedFile.readAsBytes();

    setState(() => isUploading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/teacher/update-photo'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      fileBytes,
      filename: 'profile_picture.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));

    var response = await request.send();

    if (!mounted) return;

    if (response.statusCode == 200) {
      await fetchProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diupdate!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal upload foto.')),
      );
    }

    setState(() => isUploading = false);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0: // Materi (Manage Kelas)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MateriGuruPage()),
        );
        break;

      case 1: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardGuru()),
        );
        break;

      case 2: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfileGuruPage()),
        );
        break;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildProfileCard() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profileData?['photo'] != null
                  ? NetworkImage(
                      'http://192.168.1.7:8000/${profileData!['photo']}?v=${DateTime.now().millisecondsSinceEpoch}')
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
          profileData?['name'] ?? '',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          profileData?['email'] ?? '',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 25),
        profileItem(Icons.email, 'Email', profileData?['email'] ?? ''),
        profileItem(Icons.school, 'Role', 'Guru'),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _logout,
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

  Widget profileItem(IconData icon, String label, String value) {
    return Card(
      elevation: 3,
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

  Widget _buildBottomNavBar() {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: Colors.blue, // Sesuaikan dengan tema utama
      height: 65,
      index: _selectedIndex,
      animationDuration: const Duration(milliseconds: 300),
      items: [
        Icon(Icons.menu_book,
            size: 28,
            color: _selectedIndex == 0 ? Colors.yellow : Colors.white),
        Icon(Icons.home,
            size: 28,
            color: _selectedIndex == 1 ? Colors.yellow : Colors.white),
        Icon(Icons.person,
            size: 28,
            color: _selectedIndex == 2 ? Colors.yellow : Colors.white),
      ],
      onTap: (index) {
        _onItemTapped(index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Guru"),
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
                    child: _buildProfileCard(),
                  ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
