import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/task_model.dart';
import '../models/task_log_model.dart';

class TaskRepository {
  final SupabaseClient _client;

  TaskRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ─── Tasks CRUD ────────────────────────────────────────────

  /// Fetch all tasks for the current user
  Future<List<TaskModel>> getTasks() async {
    final data = await _client
        .from(AppConstants.tasksTable)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  /// Add a new task
  Future<TaskModel> addTask(TaskModel task) async {
    final data = await _client
        .from(AppConstants.tasksTable)
        .insert(task.toJson())
        .select()
        .single();
    return TaskModel.fromJson(data);
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await _client
        .from(AppConstants.tasksTable)
        .delete()
        .eq('id', taskId);
  }

  // ─── Task Logs ─────────────────────────────────────────────

  /// Get logs for a specific date
  Future<List<TaskLogModel>> getLogsForDate(DateTime date) async {
    final dateStr = _dateString(date);
    final data = await _client
        .from(AppConstants.taskLogsTable)
        .select()
        .eq('user_id', _userId)
        .eq('completed_date', dateStr);
    return (data as List).map((e) => TaskLogModel.fromJson(e)).toList();
  }

  /// Get all logs between two dates (for calendar month view)
  Future<List<TaskLogModel>> getLogsForRange(
      DateTime start, DateTime end) async {
    final startStr = _dateString(start);
    final endStr = _dateString(end);
    final data = await _client
        .from(AppConstants.taskLogsTable)
        .select()
        .eq('user_id', _userId)
        .gte('completed_date', startStr)
        .lte('completed_date', endStr);
    return (data as List).map((e) => TaskLogModel.fromJson(e)).toList();
  }

  /// Toggle task completion for a date.
  /// Returns `true` if the task is now completed (inserted), `false` if uncompleted (deleted).
  Future<bool> toggleTaskLog({
    required String taskId,
    required DateTime date,
  }) async {
    final dateStr = _dateString(date);

    // Check if log exists
    final existing = await _client
        .from(AppConstants.taskLogsTable)
        .select('id')
        .eq('task_id', taskId)
        .eq('user_id', _userId)
        .eq('completed_date', dateStr)
        .maybeSingle();

    if (existing != null) {
      // Remove it
      await _client
          .from(AppConstants.taskLogsTable)
          .delete()
          .eq('id', existing['id']);
      return false;
    } else {
      // Insert it
      await _client.from(AppConstants.taskLogsTable).insert({
        'task_id': taskId,
        'user_id': _userId,
        'completed_date': dateStr,
      });
      return true;
    }
  }

  // ─── Stats ─────────────────────────────────────────────────

  /// Get total completion count for the current user
  Future<int> getTotalCompletions() async {
    final data = await _client
        .from(AppConstants.taskLogsTable)
        .select('id')
        .eq('user_id', _userId);
    return (data as List).length;
  }

  /// Get streak (consecutive completion days) for a task, counting back from today
  Future<int> getStreak(String taskId) async {
    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = _dateString(date);
      final data = await _client
          .from(AppConstants.taskLogsTable)
          .select('id')
          .eq('task_id', taskId)
          .eq('completed_date', dateStr)
          .maybeSingle();
      if (data != null) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Get all logs for a user (for overall discipline score)
  Future<List<TaskLogModel>> getAllLogs() async {
    final data = await _client
        .from(AppConstants.taskLogsTable)
        .select()
        .eq('user_id', _userId);
    return (data as List).map((e) => TaskLogModel.fromJson(e)).toList();
  }

  // ─── Helpers ───────────────────────────────────────────────

  String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
