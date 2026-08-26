import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/group_model.dart';
import '../data/groups_repository.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(ref.watch(supabaseClientProvider));
});

final myGroupsProvider = StreamProvider<List<Group>>((ref) {
  return ref.watch(groupsRepositoryProvider).watchMyGroups();
});

final groupByIdProvider = FutureProvider.family<Group, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).getGroup(groupId);
});

final groupMembersProvider = StreamProvider.family<List<GroupMember>, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).watchMembers(groupId);
});
