class RetratoModel {
  String? id;
  final String title;
  final String date;
  final String caseOcurrent;
  final String eans;
  final List<String> photos;
  final List<String> videos;
  final String description;
  final String portraitMadeBy;
  final String createdAt;
  final bool isActive;

  RetratoModel({
    this.id,
    required this.title,
    required this.photos,
    required this.videos,
    required this.date,
    required this.eans,
    required this.description,
    required this.caseOcurrent,
    required this.portraitMadeBy,
    required this.createdAt,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'caseOcurrent': caseOcurrent, // Adicionado aqui
      'eans': eans,
      'photos': photos,
      'videos': videos,
      'description': description,
      'portraitMadeBy': portraitMadeBy,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory RetratoModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return RetratoModel(
      id: docId,
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      caseOcurrent: json['caseOcurrent'] ?? '',
      eans: json['eans'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      description: json['description'] ?? '',
      portraitMadeBy: json['portraitMadeBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}
