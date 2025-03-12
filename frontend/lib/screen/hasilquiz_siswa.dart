import 'package:flutter/material.dart';

class HasilKuisPage extends StatelessWidget {
  final int totalSoal;
  final int jawabanBenar;
  final double skor;

  HasilKuisPage({
    required this.totalSoal,
    required this.jawabanBenar,
    required this.skor,
  });

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
              Text("Skor Akhir: $skor"),

              /// **Tampilkan Badge jika skor 100**
              if (skor == 100)
                Column(
                  children: [
                    Icon(Icons.emoji_events, size: 50, color: Colors.amber),
                    Text("🎖 Badge Baru Diterima!",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
