import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/friends/presentation/friend_detail_screen.dart';
import '../../features/groups/presentation/group_detail_screen.dart';
import '../../features/home/home_shell.dart';
import '../supabase/supabase_providers.dart';
import 'go_router_refresh_stream.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(supabaseClientProvider).auth;

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      final isSignedIn = auth.currentSession != null;
      final isAuthRoute = state.matchedLocation == '/sign-in' || state.matchedLocation == '/sign-up';
      if (!isSignedIn && !isAuthRoute) return '/sign-in';
      if (isSignedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (context, state) => const SignUpScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeShell()),
      GoRoute(
        path: '/groups/:groupId',
        builder: (context, state) => GroupDetailScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/friends/:friendId',
        builder: (context, state) => FriendDetailScreen(friendId: state.pathParameters['friendId']!),
      ),
    ],
  );
});
