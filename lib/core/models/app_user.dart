class AppUser {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? profileImageUrl;

  AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.profileImageUrl,
  });

  AppUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
