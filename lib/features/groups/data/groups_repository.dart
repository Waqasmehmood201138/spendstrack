import 'package:supabase_flutter/supabase_flutter.dart';

import 'group_model.dart';
import 'group_type.dart';

class GroupsRepository {
  final SupabaseClient _client;
  const GroupsRepository(this._client);

  /// Groups the current user belongs to, live via realtime on `group_members`.
  /// RLS already scopes `groups` to the caller's memberships, so a plain
  /// `select` (no explicit `.eq`) is correct and stays correct as membership
  /// changes.
  Stream<List<Group>> watchMyGroups() {
    return _client
        .from('groups')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((rows) => rows.map(Group.fromJson).toList());
  }

  Future<Group> getGroup(String groupId) async {
    final row = await _client.from('groups').select().eq('id', groupId).single();
    return Group.fromJson(row);
  }

  Stream<List<GroupMember>> watchMembers(String groupId) {
    return _client
        .from('group_members')
        .stream(primaryKey: ['group_id', 'user_id'])
        .eq('group_id', groupId)
        .asyncMap((rows) async {
          if (rows.isEmpty) return <GroupMember>[];
          final userIds = rows.map((r) => r['user_id'] as String).toList();
          final profiles = await _client.from('profiles').select().inFilter('id', userIds);
          final profilesById = {for (final p in profiles) p['id'] as String: p};
          return rows
              .map((r) => GroupMember.fromJson({...r, 'profiles': profilesById[r['user_id']]}))
              .toList();
        });
  }

  Future<String> createGroup({required String name, required GroupType type}) async {
    final id = await _client.rpc('create_group', params: {'p_name': name, 'p_group_type': type.toJson()});
    return id as String;
  }

  /// Returns the new member's user id, or throws if no account exists for
  /// that email (see docs/features-roadmap.md — inviting a not-yet-registered
  /// person happens via the group's invite link instead).
  Future<String> addMemberByEmail({required String groupId, required String email}) async {
    final id = await _client.rpc('add_group_member_by_email', params: {
      'p_group_id': groupId,
      'p_email': email,
    });
    return id as String;
  }

  Future<void> removeMember({required String groupId, required String userId}) async {
    await _client.from('group_members').delete().eq('group_id', groupId).eq('user_id', userId);
  }

  Future<void> leaveGroup(String groupId, String currentUserId) =>
      removeMember(groupId: groupId, userId: currentUserId);

  Future<String> joinByInviteToken(String inviteToken) async {
    final id = await _client.rpc('join_group_by_invite', params: {'p_invite_token': inviteToken});
    return id as String;
  }
}
