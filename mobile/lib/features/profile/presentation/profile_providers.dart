import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_profile_repository.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(Supabase.instance.client);
});

final myProfileProvider = FutureProvider.autoDispose<Profile?>((ref) {
  return ref.watch(profileRepositoryProvider).getMyProfile();
});
