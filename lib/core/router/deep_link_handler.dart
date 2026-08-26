import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/groups/providers/groups_providers.dart';

/// Handles `spendstrack://join/{invite_token}` group-invite links — both a
/// cold start (app not running, link tapped) and a link tapped while the
/// app is already open. On success, navigates straight to the joined
/// group; on failure (expired token, not signed in yet, etc.) shows a
/// snackbar via [messengerKey] rather than failing silently, since this is
/// often the very first thing a new user does with the app.
class DeepLinkHandler {
  final WidgetRef ref;
  final GoRouter router;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  StreamSubscription<Uri>? _subscription;

  DeepLinkHandler({required this.ref, required this.router, required this.messengerKey});

  Future<void> start() async {
    final appLinks = AppLinks();
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) {
      // No initial link, or platform channel not ready yet — not an error.
    }
    _subscription = appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<void> _handle(Uri uri) async {
    if (uri.scheme != 'spendstrack' || uri.host != 'join') return;
    final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (token == null || token.isEmpty) return;

    try {
      final groupId = await ref.read(groupsRepositoryProvider).joinByInviteToken(token);
      router.push('/groups/$groupId');
    } catch (e) {
      messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Could not join that group — sign in first, then try the link again.')),
      );
    }
  }
}
