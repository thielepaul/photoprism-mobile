class MomentsTime {
  final int year;
  final int month;
  int count;

  MomentsTime({this.year, this.month, this.count});

  factory MomentsTime.fromJson(Map<String, dynamic> json) {
    return MomentsTime(
      year: json['PhotoYear'].toInt() as int,
      month: json['PhotoMonth'].toInt() as int,
      count: json['Count'].toInt() as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'PhotoYear': year,
        'PhotoMonth': month,
        'Count': count,
      };
}
