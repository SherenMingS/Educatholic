import 'package:flutter/material.dart';
import 'package:frontend/screen/dashboard_siswa.dart';
import '../services/api_service.dart'; // pastikan import ApiService

class HasilKuisPage extends StatelessWidget {
  final int quizId;
  final int totalSoal;
  final int jawabanBenar;
  final double skorTerbaru;
  final double skorAkhir;
  final List<Map<String, dynamic>> jawabanSalah;

  const HasilKuisPage({
    Key? key,
    required this.quizId,
    required this.totalSoal,
    required this.jawabanBenar,
    required this.skorTerbaru,
    required this.skorAkhir,
    required this.jawabanSalah,
  }) : super(key: key);

  String getFeedback(double skor) {
    if (skor >= 80) {
      return "🎉 Kerja bagus! Kamu hampir sempurna!";
    } else if (skor >= 50) {
      return "💡 Lumayan! Yuk belajar lebih giat lagi.";
    } else {
      return "💪 Jangan menyerah, terus semangat belajar ya!";
    }
  }

  void showFeedbackDialog(BuildContext context) {
    int selectedRating = 0;
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Beri Feedback"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Seberapa puas kamu dengan kuis ini?"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                  );
                }),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(labelText: "Komentar (opsional)"),
                maxLines: 3,
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.submitQuizFeedback(
                    quizId: quizId,
                    rating: selectedRating,
                    comment: commentController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Terima kasih atas feedback-nya!")),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal mengirim feedback")),
                  );
                }
              },
              child: Text("Kirim"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: Text(
          "Hasil Kuis",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        child: IconButton(
          icon: Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DashboardSiswa()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text("Nilai Attempt Ini:", style: TextStyle(fontSize: 22)),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        skorTerbaru.toInt().toString(),
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text("Benar: $jawabanBenar dari $totalSoal"),
                      Text("Skor Attempt Ini: ${skorTerbaru.toStringAsFixed(1)}"),
                      Text("Skor Akhir: ${skorAkhir.toStringAsFixed(1)}"),
                      
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  getFeedback(skorAkhir),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                if (skorAkhir == 100)
                  Column(
                    children: [
                      Icon(Icons.emoji_events, size: 50, color: Colors.amber),
                      Text(
                        "🎖 Badge Baru Diterima!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                if (jawabanSalah.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Pembahasan Jawaban Salah"),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: jawabanSalah.length,
                              itemBuilder: (context, index) {
                                final item = jawabanSalah[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("❓ ${item['pertanyaan']}",
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4),
                                      Text("Jawaban Kamu: ${item['jawabanUser']}",
                                          style: TextStyle(color: Colors.red)),
                                      Text("Jawaban Benar: ${item['jawabanBenar']}",
                                          style: TextStyle(color: Colors.green)),
                                      Divider(),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Tutup"),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.visibility, color: Colors.white),
                    label: Text("Lihat Pembahasan", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    showFeedbackDialog(context);
                  },
                  icon: Icon(Icons.rate_review, color: Colors.white),
                  label: Text("Beri Feedback Kuis", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
