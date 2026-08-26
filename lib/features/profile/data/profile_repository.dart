import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_model.dart';

class ProfileRepository {
  final SupabaseClient _client;
  const ProfileRepository(this._client);

  Future<Profile> getById(String userId) async {
    final row = await _client.from('profiles').select().eq('id', userId).single();
    return Profile.fromJson(row);
  }

  Stream<Profile> watchCurrent(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => Profile.fromJson(rows.first));
  }

  Future<void> update({
    required String userId,
    required String firstName,
    required String lastName,
    required String defaultCurrency,
  }) async {
    await _client.from('profiles').update({
      'first_name': firstName,
      'last_name': lastName,
      'default_currency': defaultCurrency,
    }).eq('id', userId);
  }
}
