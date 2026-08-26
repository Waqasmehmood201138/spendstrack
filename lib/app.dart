import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/router/deep_link_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

class SpendsTrackApp extends ConsumerStatefulWidget {
  const SpendsTrackApp({super.key});

  @override
  ConsumerState<SpendsTrackApp> createState() => _SpendsTrackAppState();
}

class _SpendsTrackAppState extends ConsumerState<SpendsTrackApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  DeepLinkHandler? _deepLinkHandler;

  @override
  void initState() {
    super.initState();
    // Deferred to after the router provider is guaranteed built, and kept
    // as a member so its subscription outlives this build and gets
    // cancelled exactly once in dispose().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final handler = DeepLinkHandler(
        ref: ref,
        router: ref.read(appRouterProvider),
        messengerKey: _messengerKey,
      );
      _deepLinkHandler = handler;
      handler.start();
    });
  }

  @override
  void dispose() {
    _deepLinkHandler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'SpendsTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      scaffoldMessengerKey: _messengerKey,
    );
  }
}
