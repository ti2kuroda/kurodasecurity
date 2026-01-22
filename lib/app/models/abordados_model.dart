class AbordadosModel {
  String? id;
  final String title;
  final String date;
  final String caseOcurrent;
  final String eans;
  final List<String> photos;
  final List<String> videos;
  final String description;
  final String abordadoPor;
  final String testemunha;
  final String dataAbordagem;
  final String movidoPor;
  final String movidoEm;
  final bool isActive;
  final String deletedAt;
  final String deletedFor;

  AbordadosModel({
    this.id,
    required this.title,
    required this.photos,
    required this.videos,
    required this.date,
    required this.eans,
    required this.description,
    required this.caseOcurrent,
    required this.abordadoPor,
    required this.dataAbordagem,
    required this.movidoPor,
    required this.movidoEm,
    required this.isActive,
    required this.deletedAt,
    required this.deletedFor,
    required this.testemunha,
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
      'abordadoPor': abordadoPor,
      'testemunha': testemunha,
      'dataAbordagem': dataAbordagem,
      'movidoPor': movidoPor,
      'movidoEm': movidoEm,
      'isActive': isActive,
      'deletedAt': deletedAt,
      'deletedFor': deletedFor,
    };
  }

  factory AbordadosModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AbordadosModel(
      id: docId,
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      caseOcurrent: json['caseOcurrent'] ?? '',
      eans: json['eans'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      description: json['description'] ?? '',
      abordadoPor: json['abordadoPor'] ?? '',
      dataAbordagem: json['dataAbordagem'] ?? '',
      movidoPor: json['movidoPor'] ?? '',
      movidoEm: json['movidoEm'] ?? '',
      isActive: json['isActive'] ?? true,
      deletedAt: json['deletedAt'] ?? '',
      deletedFor: json['deletedFor'] ?? '',
      testemunha: json['testemunha'] ?? '',
    );
  }
}
