import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity/presentation/activity_feed_screen.dart';
import '../activity/providers/activity_providers.dart';
import '../friends/presentation/friends_list_screen.dart';
import '../groups/presentation/groups_list_screen.dart';
import '../profile/presentation/profile_screen.dart';

/// Bottom-nav shell hosting the four top-level tabs. Detail screens (group,
/// friend, expense, add-expense, settle-up) are pushed on top via
/// Navigator.push/go_router routes rather than living inside this shell —
/// see docs/architecture.md.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.group_outlined, selectedIcon: Icons.group, label: 'Groups'),
    (icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Friends'),
    (icon: Icons.notifications_outlined, selectedIcon: Icons.notifications, label: 'Activity'),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          GroupsListScreen(),
          FriendsListScreen(),
          ActivityFeedScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: i == 2 && unreadCount > 0
                  ? Badge(label: Text('$unreadCount'), child: Icon(_tabs[i].icon))
                  : Icon(_tabs[i].icon),
              selectedIcon: Icon(_tabs[i].selectedIcon),
              label: _tabs[i].label,
            ),
        ],
      ),
    );
  }
}
