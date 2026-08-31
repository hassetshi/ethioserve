import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppAuthException('You need to be logged in.');
    }
    return id;
  }

  @override
  Future<Profile?> getMyProfile() async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('user_id', _userId)
          .maybeSingle();
      return row == null ? null : Profile.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('getMyProfile failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<Profile> upsertProfile(Profile profile) async {
    try {
      final row = await _client
          .from('profiles')
          .upsert(profile.toJson(), onConflict: 'user_id')
          .select()
          .single();
      return Profile.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('upsertProfile failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }
}
