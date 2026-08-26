import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../balances/data/balance_model.dart';
import '../../balances/data/balances_repository.dart';
import '../../balances/providers/balances_providers.dart';
import '../../profile/data/profile_model.dart';
import '../data/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(ref.watch(supabaseClientProvider));
});

final friendsListProvider = StreamProvider<List<Profile>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return ref.watch(friendsRepositoryProvider).watchFriends(userId);
});

/// All of the current user's friend balances, keyed by friend id, refetched
/// whenever [balancesRepositoryProvider]'s dependents invalidate — used by
/// the friends list to show an "owes you" / "you owe" chip per row without
/// each row issuing its own query.
final allFriendBalancesProvider = FutureProvider<Map<String, List<UserBalance>>>((ref) async {
  final BalancesRepository repo = ref.watch(balancesRepositoryProvider);
  final balances = await repo.getAllFriendBalances();
  final byFriend = <String, List<UserBalance>>{};
  for (final b in balances) {
    byFriend.putIfAbsent(b.userId, () => []).add(b);
  }
  return byFriend;
});
