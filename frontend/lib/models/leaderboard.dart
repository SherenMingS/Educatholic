class LeaderboardModel {
  final int id;
  final String name;
  final String kelas;
  final int totalScore;

  LeaderboardModel({
    required this.id,
    required this.name,
    required this.kelas,
    required this.totalScore,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      id: json['id'],
      name: json['name'],
      kelas: json['kelas'],
      totalScore: int.tryParse(json['total_score'].toString()) ??
          0, // Konversi String ke int
    );
  }
}
