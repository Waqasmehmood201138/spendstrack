import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/avatar_upload_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/editable_avatar.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../balances/data/balance_model.dart';
import '../../balances/presentation/balance_summary_text.dart';
import '../../balances/providers/balances_providers.dart';
import 'add_member_dialog.dart';
import 'group_avatar.dart';
import '../data/group_model.dart';
import '../providers/groups_providers.dart';

class GroupSettingsScreen extends ConsumerWidget {
  final String groupId;
  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final myUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Group settings')),
      body: AsyncValueWidget<Group>(
        value: groupAsync,
        data: (group) {
          final balancesByUser = <String, List<UserBalance>>{};
          for (final b in balancesAsync.valueOrNull ?? const <UserBalance>[]) {
            balancesByUser.putIfAbsent(b.userId, () => []).add(b);
          }
          final myBalances = balancesByUser[myUserId] ?? const [];
          final iAmSettled = myBalances.every((b) => b.amount.isZero);

          return ListView(
            children: [
              _GroupHeaderTile(group: group),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('Group members', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: const Text('Add people to group'),
                onTap: () => showAddMemberDialog(context, groupId),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Invite via link'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: 'spendstrack://join/${group.inviteToken}'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite link copied')));
                  }
                },
              ),
              AsyncValueWidget<List<GroupMember>>(
                value: membersAsync,
                data: (members) => Column(
                  children: [
                    for (final m in members)
                      ListTile(
                        leading: UserAvatar(pictureUrl: m.pictureUrl, displayName: m.fullName),
                        title: Text(m.userId == myUserId ? '${m.fullName} (you)' : m.fullName),
                        trailing: SizedBox(
                          width: 120,
                          child: BalanceSummaryText(
                            balances: balancesByUser[m.userId] ?? const [],
                            owesYouPrefix: 'gets back',
                            youOwePrefix: 'owes',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('Advanced settings', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.hub_outlined),
                title: const Text('Simplify group debts'),
                subtitle: const Text(
                  'Automatically combines debts to reduce the total number of repayments between group members.',
                ),
                value: group.simplifyByDefault,
                onChanged: (value) async {
                  await ref.read(groupsRepositoryProvider).updateSimplifyByDefault(groupId: groupId, value: value);
                  ref.invalidate(groupByIdProvider(groupId));
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Leave group'),
                subtitle: iAmSettled
                    ? null
                    : const Text("You can't leave this group until your balance is settled up."),
                enabled: iAmSettled,
                onTap: iAmSettled
                    ? () async {
                        if (myUserId == null) return;
                        await ref.read(groupsRepositoryProvider).leaveGroup(groupId, myUserId);
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    : null,
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text('Delete group', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete this group?'),
                      content: const Text('This removes the group for everyone. Expense history is kept for records.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(groupsRepositoryProvider).deleteGroup(groupId);
                    if (context.mounted) Navigator.of(context)..pop()..pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupHeaderTile extends ConsumerStatefulWidget {
  final Group group;
  const _GroupHeaderTile({required this.group});

  @override
  ConsumerState<_GroupHeaderTile> createState() => _GroupHeaderTileState();
}

class _GroupHeaderTileState extends ConsumerState<_GroupHeaderTile> {
  bool _isUploading = false;

  Future<void> _changeLogo() async {
    setState(() => _isUploading = true);
    try {
      final url = await ref.read(avatarUploadServiceProvider).pickAndUploadGroupLogo(widget.group.id);
      if (url != null) {
        await ref.read(groupsRepositoryProvider).updateAvatarUrl(groupId: widget.group.id, avatarUrl: url);
        ref.invalidate(groupByIdProvider(widget.group.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update group logo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: EditableAvatar(
        size: 56,
        isUploading: _isUploading,
        onTap: _changeLogo,
        avatar: GroupAvatar(seed: widget.group.id, icon: widget.group.groupType.icon, avatarUrl: widget.group.avatarUrl, size: 56),
      ),
      title: Text(widget.group.name),
      subtitle: Text(widget.group.groupType.label),
    );
  }
}
