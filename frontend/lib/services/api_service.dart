import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/quiz.dart';

class ApiService {
  static const String baseUrl =
      'http://127.0.0.1:8000/api'; // Ganti dengan URL backend-mu

  static Future<List<Student>> getStudents(String kelas, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/$kelas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((student) => Student.fromJson(student)).toList();
    } else {
      throw Exception('Gagal mengambil data siswa');
    }
  }

  // API untuk mengambil daftar kuis
  static Future<List<Quiz>> getQuizzes(String token, String kelas) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes?kelas=$kelas'), // Kirim kelas ke API
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((quiz) => Quiz.fromJson(quiz)).toList();
    } else {
      throw Exception('Gagal mengambil daftar kuis');
    }
  }

//
  static Future<void> createQuiz(
      Map<String, dynamic> quizData, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quizzes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(quizData),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal membuat kuis');
    }
  }

  //
  static Future<void> updateQuiz(
      int id, Map<String, dynamic> quizData, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/quizzes/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(quizData),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal memperbarui kuis');
    }
  }

  // Fungsi untuk mendapatkan detail quiz beserta soal
  static Future<Quiz> getQuizDetail(int quizId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/$quizId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("Response Body: ${response.body}"); // Tambahkan ini

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return Quiz.fromJson(data);
    } else {
      throw Exception('Gagal mengambil detail quiz');
    }
  }

  static Future<void> deleteQuiz(int quizId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/quizzes/$quizId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus quiz: ${response.body}');
    }
  }

//student get quiz
  static Future<List<Quiz>> getQuizzesForStudents(
      String token, String? kelas) async {
    if (kelas == null || kelas.isEmpty) {
      throw Exception("⚠️ Gagal mengambil kuis: kelas tidak valid!");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/student?kelas=$kelas'), // Kirim kelas ke API
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((quiz) => Quiz.fromJson(quiz)).toList();
      } catch (e) {
        throw Exception("⚠️ Format data API tidak sesuai: $e");
      }
    } else {
      throw Exception('⚠️ Gagal mengambil daftar kuis untuk kelas $kelas');
    }
  }

  static Future<List<dynamic>> getMateri(String token, String kelas) async {
    final response = await http.get(
      Uri.parse('$baseUrl/materi?kelas=$kelas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      // Pastikan response memiliki key 'materi' yang berupa List
      if (jsonResponse.containsKey('materi') &&
          jsonResponse['materi'] is List) {
        return jsonResponse['materi'];
      } else {
        throw Exception('Format data API tidak sesuai');
      }
    } else {
      throw Exception('Gagal mengambil daftar materi untuk kelas $kelas');
    }
  }

  //get detail materi
  static Future<Map<String, dynamic>> getMateriDetail(
      String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/materi/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mengambil detail materi');
    }
  }

  static Future<Map<String, dynamic>> getQuizDetailSiswa(
      String token, int quizId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/$quizId/student'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      // **Pastikan kita hanya mengambil bagian 'data'**
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is Map) {
        return jsonResponse['data'];
      } else {
        throw Exception("⚠️ Format data API tidak sesuai: $jsonResponse");
      }
    } else {
      throw Exception('⚠️ Gagal mengambil detail kuis');
    }
  }
}
