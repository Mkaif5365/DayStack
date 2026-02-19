class TaskLogModel {
  final String id;
  final String taskId;
  final String userId;
  final DateTime completedDate;

  const TaskLogModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.completedDate,
  });

  factory TaskLogModel.fromJson(Map<String, dynamic> json) {
    return TaskLogModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      completedDate: DateTime.parse(json['completed_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'user_id': userId,
      'completed_date': completedDate.toIso8601String().split('T').first,
    };
  }
}
