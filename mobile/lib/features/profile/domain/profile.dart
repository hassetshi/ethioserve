class Profile {
  const Profile({
    required this.userId,
    this.firstName,
    this.lastName,
    this.profilePhoto,
    required this.preferredLanguage,
  });

  final String userId;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;
  final String preferredLanguage;

  bool get isComplete =>
      (firstName?.isNotEmpty ?? false) && (lastName?.isNotEmpty ?? false);

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    userId: json['user_id'] as String,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    profilePhoto: json['profile_photo'] as String?,
    preferredLanguage: json['preferred_language'] as String? ?? 'en',
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'first_name': firstName,
    'last_name': lastName,
    'profile_photo': profilePhoto,
    'preferred_language': preferredLanguage,
  };

  Profile copyWith({
    String? firstName,
    String? lastName,
    String? preferredLanguage,
  }) {
    return Profile(
      userId: userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePhoto: profilePhoto,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
