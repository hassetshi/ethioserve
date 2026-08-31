/// Normalizes Ethiopian phone numbers to E.164 (+251XXXXXXXXX) for Supabase
/// phone auth, and validates the result.
///
/// Accepts local format (09XXXXXXXX / 07XXXXXXXX), already-international
/// format (+2519XXXXXXXX), or the same without the leading '+'.
class PhoneNumberValidator {
  const PhoneNumberValidator._();

  static const String _countryCode = '251';

  /// Returns the E.164 form, or `null` if [input] isn't a recognizable
  /// Ethiopian mobile number.
  static String? normalize(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    String national;
    if (digits.startsWith(_countryCode) && digits.length == 12) {
      national = digits.substring(_countryCode.length);
    } else if (digits.startsWith('0') && digits.length == 10) {
      national = digits.substring(1);
    } else if (digits.length == 9) {
      national = digits;
    } else {
      return null;
    }

    if (!RegExp(r'^[79]\d{8}$').hasMatch(national)) return null;

    return '+$_countryCode$national';
  }

  static bool isValid(String input) => normalize(input) != null;
}
