class Config {
  Config({this.downloadToken, this.countVideos, this.previewToken});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      downloadToken: json['downloadToken'] as String,
      previewToken: json['previewToken'] as String,
      countVideos: json['count']['videos'] as int,
    );
  }

  final String downloadToken;
  final String previewToken;
  final int countVideos;
}
