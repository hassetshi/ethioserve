import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

/// Streams the current [AppUser] (or `null` if signed out). This is what
/// route guards and role-based UI depend on — never a raw Supabase session,
/// since role lives in `public.users`, not the auth session itself.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});
