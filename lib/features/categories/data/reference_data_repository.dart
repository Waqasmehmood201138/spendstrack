import 'package:supabase_flutter/supabase_flutter.dart';

import 'category_model.dart';
import 'currency_model.dart';

/// Read-only access to the seeded reference tables (`categories`,
/// `currencies`). Both are tiny and effectively static, so callers should
/// fetch once via a non-family provider rather than re-querying per screen.
class ReferenceDataRepository {
  final SupabaseClient _client;
  const ReferenceDataRepository(this._client);

  Future<List<Category>> getCategories() async {
    final rows = await _client.from('categories').select().order('id');
    return rows.map(Category.fromJson).toList();
  }

  Future<List<Currency>> getCurrencies() async {
    final rows = await _client.from('currencies').select().order('code');
    return rows.map(Currency.fromJson).toList();
  }
}
