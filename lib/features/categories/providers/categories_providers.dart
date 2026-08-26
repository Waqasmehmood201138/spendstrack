import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/category_model.dart';
import '../data/currency_model.dart';
import '../data/reference_data_repository.dart';

final referenceDataRepositoryProvider = Provider<ReferenceDataRepository>((ref) {
  return ReferenceDataRepository(ref.watch(supabaseClientProvider));
});

/// `keepAlive` (not autoDispose) — reference data doesn't change during a
/// session, so fetch once and hold it rather than refetching every time a
/// screen using it is pushed.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.keepAlive();
  final raw = await ref.watch(referenceDataRepositoryProvider).getCategories();
  return Category.resolveCategoryGroups(raw);
});

final currenciesProvider = FutureProvider<List<Currency>>((ref) {
  ref.keepAlive();
  return ref.watch(referenceDataRepositoryProvider).getCurrencies();
});

final categoryByIdProvider = Provider.family<Category?, int?>((ref, id) {
  if (id == null) return null;
  final categories = ref.watch(categoriesProvider).valueOrNull;
  if (categories == null) return null;
  for (final c in categories) {
    if (c.id == id) return c;
  }
  return null;
});
