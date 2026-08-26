import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

/// Any profile by id — used when rendering another user (friend, group
/// member, expense participant), not just the signed-in user.
final profileByIdProvider = FutureProvider.family<Profile, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).getById(userId);
});

/// The signed-in user's own profile, kept live via realtime.
final currentProfileProvider = StreamProvider<Profile>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return ref.watch(profileRepositoryProvider).watchCurrent(userId);
});
