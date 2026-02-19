import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../no_fap_provider.dart';

class NoFapScreen extends ConsumerWidget {
  const NoFapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noFapProvider);
    final streak = state.currentStreak;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.emeraldDark.withValues(alpha: 0.9),
              AppTheme.scaffoldBg,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.emeraldLight))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                const SizedBox(height: 40),
                Text(
                  'No Fap Journey',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -1,
                      ),
                ),
                const Spacer(),

                // Center Counter
                Hero(
                  tag: 'no-fap-counter',
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$streak',
                          style: const TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.emeraldLight,
                            height: 1,
                          ),
                        ),
                        const Text(
                          'DAYS SURVIVED',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        onPressed: state.isLoading
                            ? null
                            : () => _showSetDaysDialog(context, ref),
                        label: 'Set Progress',
                        icon: Icons.edit_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionButton(
                        onPressed: state.isLoading
                            ? null
                            : () => _confirmReset(context, ref),
                        label: 'Reset Counter',
                        icon: Icons.refresh_rounded,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSetDaysDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Set Progress'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'How many days have it been?',
            hintStyle: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final days = int.tryParse(controller.text) ?? 0;
              ref.read(noFapProvider.notifier).setManualDays(days);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.emeraldLight)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    if (ref.read(noFapProvider).lastResetDate == null) {
      ref.read(noFapProvider.notifier).startOrReset();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Relapse?'),
        content: const Text(
          'It\'s okay to fall. The important thing is to get back up immediately. Reset counter?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(noFapProvider.notifier).startOrReset();
            },
            child: const Text('Reset', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final Color color;

  const _ActionButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: color.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}
