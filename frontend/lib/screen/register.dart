import 'package:flutter/material.dart';
import 'package:frontend/screen/login.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  String? kelas; // Pilihan kelas siswa
  String? gender; // ✅ Jenis Kelamin

  final List<String> genderList = ['Laki-laki', 'Perempuan'];
  final String role = "siswa";

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        kelas == null ||
        gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Harap isi semua bidang!"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": nameController.text,
        "email": emailController.text,
        "password": passwordController.text,
        "password_confirmation": confirmPasswordController.text,
        "role": role,
        "kelas": kelas,
        "gender": gender, // ✅ Kirim gender ke backend
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("Registrasi Berhasil!", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ));
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("Registrasi Gagal!", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 80),
                SizedBox(height: 10),
                Text("EduCatholic",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),

                // Nama
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
                    prefixIcon: Icon(Icons.person, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 10),

                // Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 10),

                // Password
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 10),

                // Konfirmasi Password
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: "Password Confirmation",
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 10),

                // Dropdown Kelas
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: kelas,
                    hint: Text("Pilih Kelas"),
                    isExpanded: true,
                    underline: SizedBox(),
                    onChanged: (String? newValue) {
                      setState(() {
                        kelas = newValue;
                      });
                    },
                    items: ['8A', '8B'].map((kelas) {
                      return DropdownMenuItem(value: kelas, child: Text(kelas));
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10),

                // ✅ Dropdown Jenis Kelamin
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: gender,
                    hint: Text("Pilih Jenis Kelamin"),
                    isExpanded: true,
                    underline: SizedBox(),
                    onChanged: (String? newValue) {
                      setState(() {
                        gender = newValue;
                      });
                    },
                    items: genderList.map((item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),

                // Tombol Register
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: register,
                    child: Text("Register",
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // Link ke login
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Sudah punya akun? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
