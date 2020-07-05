class Config {
  Config({this.downloadToken, this.countVideos});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      downloadToken: json['downloadToken'] as String,
      countVideos: json['count']['videos'] as int,
    );
  }

  final String downloadToken;
  final int countVideos;
}
