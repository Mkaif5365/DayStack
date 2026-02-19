import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_provider.dart';
import '../../../repositories/profile_repository.dart';
import '../../../models/profile_model.dart';
import '../../tasks/task_provider.dart';
import '../../../repositories/task_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _todayCompletions = 0;
  double _disciplineScore = 0;
  bool _loading = true;
  ProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadStats);
  }

  Future<void> _loadStats() async {
    try {
      final repo = TaskRepository(Supabase.instance.client);
      final tasks = ref.read(taskProvider).tasks;
      final allLogs = await repo.getAllLogs();

      // Calculate expected completions
      int totalExpected = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (final task in tasks) {
        final start =
            DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
        final end =
            DateTime(task.endDate.year, task.endDate.month, task.endDate.day);
        final effectiveEnd = today.isBefore(end) ? today : end;
        if (!effectiveEnd.isBefore(start)) {
          totalExpected += effectiveEnd.difference(start).inDays + 1;
        }
      }

      if (mounted) {
        final profileRepo = ProfileRepository(Supabase.instance.client);
        final profile = await profileRepo.getProfile();
        final todayLogs = await repo.getLogsForDate(today);
        
        setState(() {
          _profile = profile;
          _todayCompletions = todayLogs.length;
          _disciplineScore =
              totalExpected > 0 ? allLogs.length / totalExpected : 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: Supabase.instance.client.auth.currentUser?.userMetadata?['display_name'] ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Set Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter your name...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ref.read(authProvider.notifier).updateDisplayName(name);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  if (mounted) setState(() {}); // Refresh to show new name
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.emeraldLight)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.scaffoldBg,
              AppTheme.cardBg,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.emeraldLight),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                    const SizedBox(height: 20),
                    // Avatar
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.emeraldLight,
                            AppTheme.emerald
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.emeraldLight
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (_profile?.displayName?.substring(0, 1) ?? 
                           user?.userMetadata?['display_name']?.substring(0, 1) ??
                           user?.email?.substring(0, 1) ?? 'D').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name & Email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _profile?.displayName ?? user?.userMetadata?['display_name'] ?? 'Set Name',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20, color: AppTheme.emeraldLight),
                          onPressed: () => _showEditNameDialog(context),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.task_alt_rounded,
                            label: "Today's Tasks",
                            value: '${taskState.activeTasks.length}',
                            color: AppTheme.emeraldLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Completed Today',
                            value: '$_todayCompletions',
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Discipline Score Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.gold.withValues(alpha: 0.12),
                            AppTheme.goldMuted,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: AppTheme.gold, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Stack Score',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_disciplineScore * 100).round()}%',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _disciplineScore.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor:
                                  AppTheme.cardBgLight.withValues(alpha: 0.5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.gold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Streak Section ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.divider, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🔥 Task Streaks',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (taskState.tasks.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No tasks yet. Add a task to start tracking streaks!',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            ...taskState.tasks.take(5).map((task) => FutureBuilder<int>(
                              future: TaskRepository(
                                      Supabase.instance.client)
                                  .getStreak(task.id),
                              builder: (context, snap) {
                                final streak = snap.data ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: streak > 0
                                              ? AppTheme.gold
                                                  .withValues(alpha: 0.12)
                                              : AppTheme.cardBgLight,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          streak > 0
                                              ? '$streak day streak 🔥'
                                              : 'No streak',
                                          style: TextStyle(
                                            color: streak > 0
                                                ? AppTheme.gold
                                                : AppTheme.textMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Logout ──
                    SizedBox(
                      width: double.infinity,
                      height: 56, // Increased from 52
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        icon: const Icon(Icons.logout_rounded,
                            color: AppTheme.error),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 16,
                            height: 1.2, // Improved alignment for descenders
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          side: BorderSide(
                              color: AppTheme.error.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
