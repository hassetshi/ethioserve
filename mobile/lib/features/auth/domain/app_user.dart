/// The authenticated identity + role, sourced from `public.users`
/// (not just the Supabase auth session) — role is a database value the
/// client never sets or trusts itself (spec section 31).
class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    this.phone,
    this.email,
    required this.languageCode,
    required this.isActive,
  });

  final String id;
  final UserRole role;
  final String? phone;
  final String? email;
  final String languageCode;
  final bool isActive;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        role: UserRole.fromValue(json['role'] as String),
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        languageCode: json['language_code'] as String? ?? 'en',
        isActive: json['is_active'] as bool? ?? true,
      );
}

enum UserRole {
  customer,
  provider,
  admin;

  static UserRole fromValue(String value) => switch (value) {
        'provider' => UserRole.provider,
        'admin' => UserRole.admin,
        _ => UserRole.customer,
      };
}
