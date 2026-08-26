import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The user's Appearance preference (Light / Dark / System default).
/// Session-only — there's no local-preferences store wired up yet, so this
/// resets to System default on a fresh app launch rather than silently
/// pretending to persist something it doesn't.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
