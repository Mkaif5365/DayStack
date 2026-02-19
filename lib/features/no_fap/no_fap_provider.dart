import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/profile_repository.dart';
import '../../core/services/cache_service.dart';

// ─── No Fap State ───────────────────────────────────────────

class NoFapState {
  final DateTime? lastResetDate;
  final bool isLoading;
  final String? error;

  const NoFapState({
    this.lastResetDate,
    this.isLoading = false,
    this.error,
  });

  NoFapState copyWith({
    DateTime? lastResetDate,
    bool? isLoading,
    String? error,
  }) {
    return NoFapState(
      lastResetDate: lastResetDate ?? this.lastResetDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get currentStreak {
    if (lastResetDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final resetDay = DateTime(
        lastResetDate!.year, lastResetDate!.month, lastResetDate!.day);
    final difference = today.difference(resetDay).inDays;
    return difference >= 0 ? difference : 0;
  }
}

// ─── No Fap Notifier ─────────────────────────────────────────

class NoFapNotifier extends Notifier<NoFapState> {
  late final SupabaseClient _client;

  @override
  NoFapState build() {
    _client = Supabase.instance.client;
    // Load initial data from local cache first (instant)
    final cachedDate = CacheService.getNoFapResetDate();
    debugPrint('DayStack Debug: Local cache reset date found: $cachedDate');
    
    if (cachedDate != null) {
      // Background load from Supabase to sync if online
      _loadFromMetadata();
      return NoFapState(lastResetDate: cachedDate, isLoading: false);
    }

    // If no cache, load from Supabase
    debugPrint('DayStack Debug: No local cache, fetching from cloud...');
    _loadFromMetadata();

    // Auto-refresh every hour to catch calendar transitions
    final timer = Stream.periodic(const Duration(hours: 1)).listen((_) {
      state = state.copyWith(); // Trigger a rebuild to refresh the getter
    });
    ref.onDispose(() => timer.cancel());

    return const NoFapState(isLoading: true);
  }

  Future<void> _loadFromMetadata() async {
    try {
      final repo = ProfileRepository(_client);
      final profile = await repo.getProfile();
      
      if (profile != null && profile.noFapLastReset != null) {
        debugPrint('DayStack Debug: Supabase cloud date found: ${profile.noFapLastReset}');
        
        // Update local cache to match cloud (source of truth for sync)
        await CacheService.saveNoFapResetDate(profile.noFapLastReset!);
        
        state = state.copyWith(
          lastResetDate: profile.noFapLastReset,
          isLoading: false,
        );
      } else {
        debugPrint('DayStack Debug: No Supabase profile/date found.');
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('DayStack Debug: Error loading from cloud: $e');
      // If we already have cached data, don't show an error, just stop loading
      state = state.copyWith(
        isLoading: false, 
        error: state.lastResetDate == null ? 'Offline: Using limited local data' : null,
      );
    } finally {
      if (state.isLoading) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> startOrReset() async {
    state = state.copyWith(isLoading: true);
    final now = DateTime.now();
    try {
      // Save locally first
      await CacheService.saveNoFapResetDate(now);
      state = NoFapState(lastResetDate: now, isLoading: false);

      // Sync to cloud
      final repo = ProfileRepository(_client);
      await repo.updateNoFapReset(now);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update');
    }
  }

  Future<void> setManualDays(int days) async {
    state = state.copyWith(isLoading: true);
    final now = DateTime.now();
    // Calculate the reset date by subtracting days from today
    final resetDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));
    
    try {
      // Save locally first
      await CacheService.saveNoFapResetDate(resetDate);
      state = NoFapState(lastResetDate: resetDate, isLoading: false);

      // Sync to cloud
      final repo = ProfileRepository(_client);
      await repo.updateNoFapReset(resetDate);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update');
    }
  }
}

// ─── Provider ────────────────────────────────────────────────

final noFapProvider = NotifierProvider<NoFapNotifier, NoFapState>(
  NoFapNotifier.new,
);
