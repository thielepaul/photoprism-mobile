class MomentsTime {
  MomentsTime({this.year, this.month, this.count});

  factory MomentsTime.fromJson(Map<String, dynamic> json) {
    return MomentsTime(
      year: json['Year'].toInt() as int,
      month: json['Month'].toInt() as int,
      count: json['PhotoCount'].toInt() as int,
    );
  }

  final int year;
  final int month;
  int count;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'Year': year,
        'Month': month,
        'PhotoCount': count,
      };
}
