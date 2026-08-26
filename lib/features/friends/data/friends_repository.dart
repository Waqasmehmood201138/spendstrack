import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_model.dart';

class FriendsRepository {
  final SupabaseClient _client;
  const FriendsRepository(this._client);

  /// `friendships` stores one row per direction (see docs/database-schema.md),
  /// so streaming the current user's outgoing rows and resolving each to a
  /// profile gives exactly their friend list, live.
  Stream<List<Profile>> watchFriends(String currentUserId) {
    return _client
        .from('friendships')
        .stream(primaryKey: ['user_id', 'friend_id'])
        .eq('user_id', currentUserId)
        .asyncMap((rows) async {
          if (rows.isEmpty) return <Profile>[];
          final friendIds = rows.map((r) => r['friend_id'] as String).toList();
          final profiles = await _client.from('profiles').select().inFilter('id', friendIds);
          return profiles.map(Profile.fromJson).toList();
        });
  }

  Future<String> addFriendByEmail(String email) async {
    final id = await _client.rpc('add_friend_by_email', params: {'p_email': email});
    return id as String;
  }

  /// Removes both directions of the friendship via RPC — RLS only lets a
  /// client delete rows it owns (`user_id = auth.uid()`), so a plain delete
  /// here would leave the friend's reverse row in place.
  Future<void> removeFriend(String friendId) async {
    await _client.rpc('remove_friend', params: {'p_friend_id': friendId});
  }
}
