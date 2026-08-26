import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// True once we've received at least one auth-state event and there's no
/// active session — the router's redirect logic waits on this to avoid
/// bouncing to /sign-in during the initial "unknown yet" instant on cold
/// start.
final isSignedInProvider = Provider<bool>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentSession != null;
});
