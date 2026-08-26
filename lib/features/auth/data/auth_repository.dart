import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;
  const AuthRepository(this._client);

  Session? get currentSession => _client.auth.currentSession;

  Future<AuthResponse> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// `data:` is written into `auth.users.raw_user_meta_data`, read by the
  /// `handle_new_user` trigger to seed the profiles row's name.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'first_name': firstName, 'last_name': lastName},
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
