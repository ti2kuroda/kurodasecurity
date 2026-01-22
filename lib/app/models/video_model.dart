class VideoInfo {
  final String caminho;
  final String titulo;
  final String descricao;

  VideoInfo({
    required this.caminho,
    required this.titulo,
    required this.descricao,
  });

  factory VideoInfo.fromMap(Map<String, dynamic> map) {
    return VideoInfo(
      caminho: map['caminho'],
      titulo: map['titulo'],
      descricao: map['descricao'],
    );
  }
}
