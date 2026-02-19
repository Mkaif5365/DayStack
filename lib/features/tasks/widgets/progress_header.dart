import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProgressHeader extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;

  const ProgressHeader({
    super.key,
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.emerald.withValues(alpha: 0.6),
            AppTheme.emeraldDark.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.emeraldLight.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Progress',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completed / $total completed',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Percentage
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.emeraldLight.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppTheme.emeraldLight.withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: percentage == 100
                          ? AppTheme.gold
                          : AppTheme.emeraldLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.cardBgLight.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage == 100 ? AppTheme.gold : AppTheme.emeraldLight,
              ),
            ),
          ),
          if (percentage == 100) ...[
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration_rounded,
                    color: AppTheme.gold, size: 18),
                SizedBox(width: 6),
                Text(
                  'All tasks completed! 🎉',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
