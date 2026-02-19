class AppConstants {
  AppConstants._();

  static const String appName = 'DayStack';

  // Supabase table names
  static const String profilesTable = 'profiles';
  static const String tasksTable = 'tasks';
  static const String taskLogsTable = 'task_logs';

  // Task categories
  static const List<String> categories = [
    'Deen',
    'Study',
    'Health',
    'Personal',
  ];

  // Category emoji map
  static const Map<String, String> categoryEmojis = {
    'Deen': '🕌',
    'Study': '📚',
    'Health': '💪',
    'Personal': '🧘',
  };
}
