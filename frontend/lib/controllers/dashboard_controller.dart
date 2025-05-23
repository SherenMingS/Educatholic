import 'dart:convert';
import 'package:frontend/services/api_service.dart';
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
  var badgeLevel = ''.obs; // ✅ Tambahkan ini
  var lastAttendance = Rxn<Map<String, dynamic>>();

  void fetchDashboard(String token) async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/dashboard-siswa"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        name.value = data['name'];
        quizAverage.value = data['quiz_average'].toDouble();
        badges.value = data['badges'] ?? [];
        badgesCount.value = data['badges_count'] ?? 0;
        badgeLevel.value =
            data['badge_level'] ?? 'Belum Punya Badge ❌'; // ✅ Tambahkan ini
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
        Uri.parse("${ApiService.baseUrl}/dashboard-guru"),
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

  void fetchLastAttendance(String kelas) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiService.baseUrl}/attendance-sessions/last?kelas=$kelas'),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          lastAttendance.value = data['data'];
        } else {
          lastAttendance.value = null;
        }
      }
    } catch (e) {
      print("Error fetching last attendance: $e");
    }
  }
}
