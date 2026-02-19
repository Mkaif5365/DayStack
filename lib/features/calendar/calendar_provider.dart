import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/task_repository.dart';
import '../../models/task_model.dart';
import '../tasks/task_provider.dart';

// ─── Calendar State ──────────────────────────────────────────

class CalendarState {
  final DateTime focusedMonth;
  final Map<DateTime, double> dayCompletionMap; // date → completion ratio
  final Map<DateTime, List<TaskModel>> missedTasksMap;
  final bool isLoading;

  const CalendarState({
    required this.focusedMonth,
    this.dayCompletionMap = const {},
    this.missedTasksMap = const {},
    this.isLoading = false,
  });

  CalendarState copyWith({
    DateTime? focusedMonth,
    Map<DateTime, double>? dayCompletionMap,
    Map<DateTime, List<TaskModel>>? missedTasksMap,
    bool? isLoading,
  }) {
    return CalendarState(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      dayCompletionMap: dayCompletionMap ?? this.dayCompletionMap,
      missedTasksMap: missedTasksMap ?? this.missedTasksMap,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Calendar Notifier ───────────────────────────────────────

class CalendarNotifier extends Notifier<CalendarState> {
  late final TaskRepository _repo;

  @override
  CalendarState build() {
    _repo = ref.read(taskRepositoryProvider);
    return CalendarState(focusedMonth: DateTime.now());
  }

  /// Load completion data for the current focused month
  Future<void> loadMonth([DateTime? month]) async {
    final m = month ?? state.focusedMonth;
    state = state.copyWith(isLoading: true, focusedMonth: m);

    try {
      final firstDay = DateTime(m.year, m.month, 1);
      final lastDay = DateTime(m.year, m.month + 1, 0);

      // Get all tasks
      final tasks = ref.read(taskProvider).tasks;
      // Get logs for this month
      final logs = await _repo.getLogsForRange(firstDay, lastDay);

      final Map<DateTime, double> completionMap = {};
      final Map<DateTime, List<TaskModel>> missedTasksMap = {};

      for (int day = 1; day <= lastDay.day; day++) {
        final date = DateTime(m.year, m.month, day);
        final activeTasks = tasks.where((t) => t.isActiveOn(date)).toList();

        if (activeTasks.isEmpty) continue;

        final logsForDay = logs.where((l) {
          final logDate = DateTime(
              l.completedDate.year, l.completedDate.month, l.completedDate.day);
          return logDate.year == date.year &&
              logDate.month == date.month &&
              logDate.day == date.day;
        }).toList();

        final ratio = logsForDay.length / activeTasks.length;
        final dateKey = DateTime(date.year, date.month, date.day);
        completionMap[dateKey] = ratio.clamp(0.0, 1.0);

        // Track missed tasks
        final completedTaskIds = logsForDay.map((l) => l.taskId).toSet();
        final missed =
            activeTasks.where((t) => !completedTaskIds.contains(t.id)).toList();
        if (missed.isNotEmpty) {
          missedTasksMap[dateKey] = missed;
        }
      }

      state = state.copyWith(
        dayCompletionMap: completionMap,
        missedTasksMap: missedTasksMap,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void changeFocusedMonth(DateTime month) {
    loadMonth(month);
  }
}

// ─── Provider ────────────────────────────────────────────────

final calendarProvider = NotifierProvider<CalendarNotifier, CalendarState>(
  CalendarNotifier.new,
);
