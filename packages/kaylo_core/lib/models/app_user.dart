/// The signed-in customer as the app shows them: the person row behind
/// a sign-in, or the sign-in identity itself until that row exists.
class AppUser {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? profileImageUrl;

  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.profileImageUrl,
  });

  /// Builds a user from the single display name providers and the
  /// persons table carry, splitting on the first space.
  factory AppUser.fromFullName({
    required String id,
    required String fullName,
    required String phone,
    String? email,
    String? profileImageUrl,
  }) {
    final (first, last) = splitName(fullName);
    return AppUser(
      id: id,
      firstName: first,
      lastName: last,
      phone: phone,
      email: email,
      profileImageUrl: profileImageUrl,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'profileImageUrl': profileImageUrl,
      };

  String get fullName => '$firstName $lastName'.trim();

  /// What to show under the name: the phone if there is one, else the
  /// email (Google sign-ins may have no phone).
  String get contactLine => phone.isNotEmpty ? phone : (email ?? '');

  static (String, String) splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    return (parts.first, parts.skip(1).join(' '));
  }

  AppUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? profileImageUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.phone == phone &&
      other.email == email &&
      other.profileImageUrl == profileImageUrl;

  @override
  int get hashCode =>
      Object.hash(id, firstName, lastName, phone, email, profileImageUrl);
}
