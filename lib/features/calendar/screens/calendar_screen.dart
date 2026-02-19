import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../calendar_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(calendarProvider.notifier).loadMonth());
  }

  @override
  Widget build(BuildContext context) {
    final calState = ref.watch(calendarProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Monthly Overview',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Track your daily discipline progress',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),

            // Calendar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.divider, width: 0.5),
              ),
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => _selectedDay == day,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  ref
                      .read(calendarProvider.notifier)
                      .changeFocusedMonth(focusedDay);
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle:
                      const TextStyle(color: AppTheme.textPrimary),
                  weekendTextStyle:
                      const TextStyle(color: AppTheme.textSecondary),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.emeraldLight.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.emeraldLight,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  cellMargin: const EdgeInsets.all(4),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(Icons.chevron_left_rounded,
                      color: AppTheme.textSecondary),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary),
                  titleTextStyle: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final dateKey =
                        DateTime(day.year, day.month, day.day);
                    final ratio = calState.dayCompletionMap[dateKey];

                    Color? bgColor;
                    if (ratio != null) {
                      if (ratio >= 1.0) {
                        bgColor = AppTheme.success.withValues(alpha: 0.25);
                      } else if (ratio > 0) {
                        bgColor = AppTheme.warning.withValues(alpha: 0.25);
                      } else if (dateKey.isBefore(today)) {
                        bgColor = AppTheme.missed.withValues(alpha: 0.2);
                      }
                    } else if (dateKey.isBefore(today)) {
                      // Past day with no data & no active tasks → no color
                    }

                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: dateKey.isAfter(today)
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _legendItem('Complete', AppTheme.success),
                  _legendItem('Partial', AppTheme.warning),
                  _legendItem('Missed', AppTheme.missed),
                  _legendItem('Future', AppTheme.textMuted),
                ],
              ),
            ),

            // Selected day details
            if (_selectedDay != null) ...[
              const SizedBox(height: 20),
              _buildDayDetail(calState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDayDetail(CalendarState calState) {
    final dateKey = DateTime(
        _selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final ratio = calState.dayCompletionMap[dateKey];
    final percentage = ratio != null ? (ratio * 100).round() : 0;

    final missedTasks = calState.missedTasksMap[dateKey] ?? [];

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider, width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _colorForRatio(ratio).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${_selectedDay!.day}',
                      style: TextStyle(
                        color: _colorForRatio(ratio),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$percentage% completed',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio ?? 0,
                          minHeight: 5,
                          backgroundColor:
                              AppTheme.cardBgLight.withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _colorForRatio(ratio)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (missedTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppTheme.divider),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Missed Tasks:',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...missedTasks.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.close_rounded,
                            color: AppTheme.error, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          t.title,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorForRatio(double? ratio) {
    if (ratio == null) return AppTheme.textMuted;
    if (ratio >= 1.0) return AppTheme.success;
    if (ratio > 0) return AppTheme.warning;
    return AppTheme.missed;
  }
}
