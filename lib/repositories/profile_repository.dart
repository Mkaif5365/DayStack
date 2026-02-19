import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  Future<ProfileModel?> getProfile() async {
    final userId = _userId;
    if (userId == null) return null;

    final data = await _client
        .from(AppConstants.profilesTable)
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> upsertProfile(ProfileModel profile) async {
    final data = await _client
        .from(AppConstants.profilesTable)
        .upsert(profile.toJson())
        .select()
        .single();
    return ProfileModel.fromJson(data);
  }

  Future<void> updateDisplayName(String name) async {
    final userId = _userId;
    if (userId == null) return;

    await _client
        .from(AppConstants.profilesTable)
        .update({'display_name': name})
        .eq('id', userId);
  }

  Future<void> updateNoFapReset(DateTime date) async {
    final userId = _userId;
    if (userId == null) return;

    await _client
        .from(AppConstants.profilesTable)
        .update({'no_fap_last_reset': date.toIso8601String()})
        .eq('id', userId);
  }
}
