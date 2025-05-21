import 'package:flutter/material.dart';
import 'package:frontend/screen/dashboard_siswa.dart';

class HasilKuisPage extends StatelessWidget {
  final int totalSoal;
  final int jawabanBenar;
  final double skor;
  final List<Map<String, dynamic>> jawabanSalah;

  const HasilKuisPage({
    Key? key,
    required this.totalSoal,
    required this.jawabanBenar,
    required this.skor,
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
                Text("Nilai Kamu:", style: TextStyle(fontSize: 22)),
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
                        skor.toInt().toString(),
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                          "Soal Terjawab Benar: $jawabanBenar dari $totalSoal"),
                      Text("Skor Akhir: ${skor.toStringAsFixed(1)}"),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  getFeedback(skor),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                if (skor == 100)
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
                if (skor < 100 && jawabanSalah.isNotEmpty)
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("❓ ${item['pertanyaan']}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4),
                                      Text(
                                          "Jawaban Kamu: ${item['jawabanUser']}",
                                          style: TextStyle(color: Colors.red)),
                                      Text(
                                          "Jawaban Benar: ${item['jawabanBenar']}",
                                          style:
                                              TextStyle(color: Colors.green)),
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
                    label: Text("Lihat Pembahasan",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
