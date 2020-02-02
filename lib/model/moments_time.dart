class MomentsTime {
  MomentsTime({this.year, this.month, this.count});

  factory MomentsTime.fromJson(Map<String, dynamic> json) {
    return MomentsTime(
      year: json['PhotoYear'].toInt() as int,
      month: json['PhotoMonth'].toInt() as int,
      count: json['Count'].toInt() as int,
    );
  }

  final int year;
  final int month;
  int count;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'PhotoYear': year,
        'PhotoMonth': month,
        'Count': count,
      };
}
