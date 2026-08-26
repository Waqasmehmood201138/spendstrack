import 'package:flutter_test/flutter_test.dart';
import 'package:spendstrack/features/profile/data/profile_model.dart';

void main() {
  test('Profile.fromJson(toJson(x)) round-trips exactly', () {
    const profile = Profile(
      id: 'user-1',
      email: 'a@example.com',
      firstName: 'Ada',
      lastName: 'Lovelace',
      pictureUrl: 'https://example.com/a.png',
      defaultCurrency: 'USD',
      locale: 'en',
    );
    final roundTripped = Profile.fromJson(profile.toJson());
    expect(roundTripped, profile);
  });

  test('fromJson defaults last_name/currency/locale when absent, matching the Postgres column defaults', () {
    final profile = Profile.fromJson({
      'id': 'user-1',
      'email': 'a@example.com',
      'first_name': 'Ada',
      'picture_url': null,
    });
    expect(profile.lastName, '');
    expect(profile.defaultCurrency, 'USD');
    expect(profile.locale, 'en');
  });
}
