import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordOtpPage extends StatefulWidget {
  @override
  _ResetPasswordOtpPageState createState() => _ResetPasswordOtpPageState();
}

class _ResetPasswordOtpPageState extends State<ResetPasswordOtpPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitReset() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password tidak sama")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text,
        'otp': _otpController.text,
        'password': _passwordController.text,
        'password_confirmation': _confirmController.text,
      }),
    );

    setState(() => _isLoading = false);

    final result = jsonDecode(response.body);
    if (response.statusCode == 200 && result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password berhasil direset.")),
      );
      Navigator.pop(context); // Kembali ke login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal mereset password')),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            children: [
              // ⬅️ Tombol back rata kiri
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Text(
                'Reset password OTP',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Masukkan data untuk mereset password',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField(
                  label: 'Kode OTP',
                  controller: _otpController,
                  keyboardType: TextInputType.number),
              _buildTextField(
                  label: 'Password Baru',
                  controller: _passwordController,
                  obscure: true),
              _buildTextField(
                  label: 'Konfirmasi Password',
                  controller: _confirmController,
                  obscure: true),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          "Reset Password",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
