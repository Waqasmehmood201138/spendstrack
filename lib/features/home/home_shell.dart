import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity/presentation/activity_feed_screen.dart';
import '../activity/providers/activity_providers.dart';
import '../friends/presentation/friends_list_screen.dart';
import '../groups/presentation/groups_list_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../profile/providers/profile_providers.dart';

/// Bottom-nav shell hosting the four top-level tabs — Groups, Friends,
/// Activity, Account — matching Splitwise's own tab set and naming exactly.
/// Detail screens (group, friend, expense, add-expense, settle-up) are
/// pushed on top via Navigator.push/go_router routes rather than living
/// inside this shell — see docs/architecture.md.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final myProfile = ref.watch(currentProfileProvider).valueOrNull;

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
          const NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Groups'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Friends'),
          NavigationDestination(
            icon: unreadCount > 0
                ? Badge(label: Text('$unreadCount'), child: const Icon(Icons.image_outlined))
                : const Icon(Icons.image_outlined),
            selectedIcon: const Icon(Icons.image),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  (myProfile?.pictureUrl != null) ? NetworkImage(myProfile!.pictureUrl!) : null,
              child: myProfile?.pictureUrl == null
                  ? Text(
                      myProfile?.firstName.isNotEmpty == true ? myProfile!.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
