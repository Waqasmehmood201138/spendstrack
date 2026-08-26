import 'dart:async';

import 'package:flutter/foundation.dart';

/// Turns any [Stream] into a [Listenable] so it can drive go_router's
/// `refreshListenable`. Standard go_router cookbook adapter — used here to
/// make the router re-evaluate `redirect` on every Supabase auth state
/// change (sign in, sign out, token refresh).
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
