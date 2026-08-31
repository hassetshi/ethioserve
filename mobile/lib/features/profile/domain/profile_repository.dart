import 'profile.dart';

abstract class ProfileRepository {
  Future<Profile?> getMyProfile();

  /// Creates the profile row if it doesn't exist yet, otherwise updates it.
  Future<Profile> upsertProfile(Profile profile);
}
