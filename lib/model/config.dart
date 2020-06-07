class Config {
  Config({this.downloadToken});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      downloadToken: json['downloadToken'] as String,
    );
  }

  final String downloadToken;
}
