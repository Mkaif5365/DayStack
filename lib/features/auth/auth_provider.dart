import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../models/profile_model.dart';

// ─── Auth State ──────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// ─── Auth Notifier ───────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = AuthRepository(Supabase.instance.client);

    // Check initial session
    final user = _repo.currentUser;
    if (user != null) {
      return AuthState(status: AuthStatus.authenticated, user: user);
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repo.signIn(email: email, password: password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repo.signUp(email: email, password: password);
      if (response.user != null && response.session != null) {
        // Create profile record
        final profileRepo = ProfileRepository(Supabase.instance.client);
        await profileRepo.upsertProfile(ProfileModel(
          id: response.user!.id,
          updatedAt: DateTime.now(),
        ));
        
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Check your email to confirm your account.',
        );
      }
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.resetPassword(email: email);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      );
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  /// Sign out
  Future<void> updateDisplayName(String name) async {
    try {
      final profileRepo = ProfileRepository(Supabase.instance.client);
      await profileRepo.updateDisplayName(name);
      
      // Update local state if needed (user metadata might still be used for initial loading)
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'display_name': name}),
      );
      
      final response = await Supabase.instance.client.auth.getUser();
      state = state.copyWith(user: response.user);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ─── Provider ────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
