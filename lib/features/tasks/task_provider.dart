import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/task_model.dart';
import '../../models/task_log_model.dart';
import '../../repositories/task_repository.dart';

// ─── Task Repository Provider ────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(Supabase.instance.client);
});

// ─── Task List State ─────────────────────────────────────────

class TaskListState {
  final List<TaskModel> tasks;
  final List<TaskLogModel> todayLogs;
  final bool isLoading;
  final String? error;

  const TaskListState({
    this.tasks = const [],
    this.todayLogs = const [],
    this.isLoading = false,
    this.error,
  });

  TaskListState copyWith({
    List<TaskModel>? tasks,
    List<TaskLogModel>? todayLogs,
    bool? isLoading,
    String? error,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      todayLogs: todayLogs ?? this.todayLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isCompletedToday(String taskId) {
    return todayLogs.any((log) => log.taskId == taskId);
  }

  int get completedToday => todayLogs.length;

  double get todayProgress {
    final active = activeTasks;
    if (active.isEmpty) return 0;
    // Only count logs for tasks that are actually active today
    final completedActive =
        todayLogs.where((log) => active.any((t) => t.id == log.taskId)).length;
    return completedActive / active.length;
  }

  List<TaskModel> get activeTasks {
    final now = DateTime.now();
    return tasks.where((t) => t.isActiveOn(now)).toList();
  }
}

// ─── Task Notifier ───────────────────────────────────────────

class TaskNotifier extends Notifier<TaskListState> {
  late final TaskRepository _repo;

  @override
  TaskListState build() {
    _repo = ref.read(taskRepositoryProvider);
    return const TaskListState();
  }

  /// Load all tasks and today's logs
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repo.getTasks();
      final todayLogs = await _repo.getLogsForDate(DateTime.now());
      state = TaskListState(
        tasks: tasks,
        todayLogs: todayLogs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load tasks',
      );
    }
  }

  /// Add a new task
  Future<void> addTask(TaskModel task) async {
    try {
      final newTask = await _repo.addTask(task);
      state = state.copyWith(
        tasks: [newTask, ...state.tasks],
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to add task');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _repo.deleteTask(taskId);
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != taskId).toList(),
        todayLogs: state.todayLogs.where((l) => l.taskId != taskId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete task');
    }
  }

  /// Toggle task completion for today
  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      final now = DateTime.now();
      final completed = await _repo.toggleTaskLog(
        taskId: taskId,
        date: now,
      );

      if (completed) {
        // Add to today's logs
        final newLog = TaskLogModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          taskId: taskId,
          userId: Supabase.instance.client.auth.currentUser!.id,
          completedDate: now,
        );
        state = state.copyWith(
          todayLogs: [...state.todayLogs, newLog],
        );
      } else {
        // Remove from today's logs
        state = state.copyWith(
          todayLogs:
              state.todayLogs.where((l) => l.taskId != taskId).toList(),
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update task');
    }
  }
}

// ─── Provider ────────────────────────────────────────────────

final taskProvider = NotifierProvider<TaskNotifier, TaskListState>(
  TaskNotifier.new,
);
