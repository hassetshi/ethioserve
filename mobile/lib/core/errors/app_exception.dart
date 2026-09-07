/// Base type for all errors that cross a repository/service boundary into
/// the UI layer. UI code catches [AppException] and shows [userMessage];
/// it must never render a raw exception/stack trace to the user (spec
/// section 29). Technical detail goes to [AppLogger], not to the screen.
sealed class AppException implements Exception {
  const AppException(this.userMessage, {this.debugDetail});

  final String userMessage;
  final String? debugDetail;

  @override
  String toString() => 'AppException: $userMessage (${debugDetail ?? ''})';
}

class NetworkException extends AppException {
  const NetworkException({super.debugDetail})
    : super('Something went wrong. Please try again.');
}

/// Named `AppAuthException` (not `AuthException`) to avoid colliding with
/// `supabase_flutter`'s own `AuthException`, which repository code needs to
/// catch separately.
class AppAuthException extends AppException {
  const AppAuthException(super.userMessage, {super.debugDetail});
}

class ValidationException extends AppException {
  const ValidationException(super.userMessage, {super.debugDetail});
}

class UnknownAppException extends AppException {
  const UnknownAppException({super.debugDetail})
    : super('Something went wrong. Please try again.');
}
