import 'package:flutter/material.dart';

class HasilKuisPage extends StatelessWidget {
  final int totalSoal;
  final int jawabanBenar;
  final double skor;
  final List<Map<String, dynamic>> jawabanSalah; // ⬅️ Tambahan

  HasilKuisPage({
    required this.totalSoal,
    required this.jawabanBenar,
    required this.skor,
    required this.jawabanSalah,
  });

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
      appBar: AppBar(title: Text("Hasil Kuis"), backgroundColor: Colors.blue),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Nilai Kamu:", style: TextStyle(fontSize: 22)),
              SizedBox(height: 10),
              Text(
                skor.toInt().toString(),
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text("Soal Terjawab Benar: $jawabanBenar dari $totalSoal"),
              Text("Skor Akhir: ${skor.toStringAsFixed(1)}"),
              SizedBox(height: 20),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("❓ ${item['pertanyaan']}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text("Jawaban Kamu: ${item['jawabanUser']}",
                                        style: TextStyle(color: Colors.red)),
                                    Text(
                                        "Jawaban Benar: ${item['jawabanBenar']}",
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
                  label: Text("Lihat Pembahasan",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
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
    );
  }
}
