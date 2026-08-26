import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The single Supabase client instance. Assumes `Supabase.initialize` already
/// ran in `main.dart` before the widget tree (and therefore this provider) is
/// ever read.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Emits every auth state change (sign in, sign out, token refresh). Feeds
/// [core/router/go_router_refresh_stream.dart] so the router reacts live.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// The current user's id, or null when signed out. Convenience over reading
/// [authStateChangesProvider] + currentSession everywhere a caller just needs
/// "who am I".
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateChangesProvider);
  return Supabase.instance.client.auth.currentUser?.id;
});
