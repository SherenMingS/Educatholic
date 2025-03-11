import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class DashboardController extends GetxController {
  var name = "".obs;
  var quizAverage = 0.0.obs;
  var badges = [].obs;
  var recentActivities = [].obs;
  var isLoading = true.obs;
  var badgesCount =
      0.obs; // Tambahkan variabel ini untuk menyimpan jumlah badges

  void fetchDashboard(String token) async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/api/dashboard-siswa"),
        headers: {
          "Authorization": "Bearer $token", // Gunakan token dari login
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        name.value = data['name'];
        quizAverage.value = data['quiz_average'].toDouble();
        badges.value = data['badges'] ?? []; // Simpan daftar badges
        badgesCount.value = data['badges_count'] ?? 0; // Update jumlah badges
        recentActivities.value = List<String>.from(data['recent_activities']);
      } else {
        print("Error response: ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading(false);
    }
  }

  void fetchDashboardGuru(String token) async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/api/dashboard-guru"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        name.value = data['name']; // Pastikan name diperbarui
      } else {
        print("Error response: ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading(false);
    }
  }
}
