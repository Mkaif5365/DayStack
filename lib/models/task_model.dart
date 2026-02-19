class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final DateTime startDate;
  final int totalDays;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.startDate,
    required this.totalDays,
    required this.createdAt,
  });

  /// End date (inclusive) = startDate + totalDays - 1
  DateTime get endDate => startDate.add(Duration(days: totalDays - 1));

  /// Whether a given date falls within this task's active range
  bool isActiveOn(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  /// Days remaining from a given date (inclusive of that date)
  int daysRemaining(DateTime fromDate) {
    final d = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = e.difference(d).inDays + 1;
    return diff < 0 ? 0 : diff;
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      totalDays: json['total_days'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'category': category,
      'start_date': startDate.toIso8601String().split('T').first,
      'total_days': totalDays,
    };
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    DateTime? startDate,
    int? totalDays,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      totalDays: totalDays ?? this.totalDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
