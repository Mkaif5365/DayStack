import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/progress_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load tasks on first build
    Future.microtask(() => ref.read(taskProvider.notifier).loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);
    final activeTasks = state.activeTasks;
    final today = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.emeraldLight),
              )
            : RefreshIndicator(
                color: AppTheme.emeraldLight,
                backgroundColor: AppTheme.cardBg,
                onRefresh: () => ref.read(taskProvider.notifier).loadTasks(),
                child: CustomScrollView(
                  slivers: [
                    // ── Header ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DayStack 👋',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(today),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Progress Card ──
                    SliverToBoxAdapter(
                      child: ProgressHeader(
                        completed: activeTasks
                            .where((t) => state.isCompletedToday(t.id))
                            .length,
                        total: activeTasks.length,
                        progress: state.todayProgress,
                      ),
                    ),

                    // ── Section Title ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Tasks",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldLight
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${activeTasks.length} tasks',
                                style: const TextStyle(
                                  color: AppTheme.emeraldLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Empty State ──
                    if (activeTasks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.task_alt_rounded,
                                size: 64,
                                color: AppTheme.textMuted
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No active tasks today',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add your first task',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Task List ──
                    if (activeTasks.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final task = activeTasks[index];
                              final isCompleted =
                                  state.isCompletedToday(task.id);
                              return TaskCard(
                                task: task,
                                isCompleted: isCompleted,
                                onToggle: () => ref
                                    .read(taskProvider.notifier)
                                    .toggleTaskCompletion(task.id),
                                onDelete: () => ref
                                    .read(taskProvider.notifier)
                                    .deleteTask(task.id),
                              );
                            },
                            childCount: activeTasks.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
