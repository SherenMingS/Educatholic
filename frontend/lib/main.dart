import 'package:flutter/material.dart';
import 'package:frontend/screen/login.dart';
import 'package:frontend/screen/dashboard_siswa.dart';
import 'package:frontend/screen/dashboard_guru.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  MyApp({this.token, this.role});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blue,
            ),
            colorScheme:
                ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
              secondary: Colors.blueAccent,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.blue, // 🔥 Ganti primaryColor di Dark Mode
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blue,
            ),
            cardColor: const Color(0xFF1E1E1E), // Kartu warna gelap
            iconTheme: const IconThemeData(color: Colors.white),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
            ),
          ),
          home: token == null
              ? LoginScreen()
              : (role == "siswa" ? DashboardSiswa() : DashboardGuru()),
        );
      },
    );
  }
}
