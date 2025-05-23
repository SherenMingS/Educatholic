class LeaderboardModel {
  final int id;
  final String name;
  final String kelas;
  final int totalScore;
  final double? averageScore; // ✅ Tambahkan ini

  LeaderboardModel({
    required this.id,
    required this.name,
    required this.kelas,
    required this.totalScore,
    this.averageScore, // ✅ Tambahkan ini
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      id: json['id'],
      name: json['name'],
      kelas: json['kelas'],
      totalScore: int.tryParse(json['total_score'].toString()) ?? 0,
      averageScore: json['average_score'] != null
          ? (json['average_score'] as num).toDouble()
          : null, // ✅ Parsing nilai rata-rata
    );
  }
}
