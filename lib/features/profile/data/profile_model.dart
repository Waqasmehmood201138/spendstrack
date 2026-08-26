/// Mirrors `public.profiles`. Shared across nearly every feature (friends,
/// groups, expense participants, comments), so it lives in its own feature
/// rather than being duplicated per consumer.
class Profile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? pictureUrl;
  final String defaultCurrency;
  final String locale;

  const Profile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.pictureUrl,
    required this.defaultCurrency,
    required this.locale,
  });

  String get fullName => lastName.isEmpty ? firstName : '$firstName $lastName';

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String? ?? '',
        pictureUrl: json['picture_url'] as String?,
        defaultCurrency: json['default_currency'] as String? ?? 'USD',
        locale: json['locale'] as String? ?? 'en',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'picture_url': pictureUrl,
        'default_currency': defaultCurrency,
        'locale': locale,
      };

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.id == id &&
      other.email == email &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.pictureUrl == pictureUrl &&
      other.defaultCurrency == defaultCurrency &&
      other.locale == locale;

  @override
  int get hashCode =>
      Object.hash(id, email, firstName, lastName, pictureUrl, defaultCurrency, locale);
}
