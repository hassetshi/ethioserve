/// Normalizes phone numbers to E.164 for Supabase phone auth, and validates
/// the result.
///
/// Supports US (NANP, +1) and Ethiopian (+251) numbers: the initial market
/// is Ethiopian-American businesses/customers in the US, with a planned
/// expansion back to Ethiopia itself, so both formats need to keep working
/// rather than picking one and dropping the other.
class PhoneNumberValidator {
  const PhoneNumberValidator._();

  static final RegExp _ethiopianNational = RegExp(r'^[79]\d{8}$');
  static final RegExp _usNational = RegExp(r'^[2-9]\d{9}$');

  /// Returns the E.164 form, or `null` if [input] isn't a recognizable US or
  /// Ethiopian mobile number.
  static String? normalize(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    // Ethiopia: +251XXXXXXXXX (12 digits with country code), 0XXXXXXXXX
    // (10-digit local form), or the bare 9-digit national number.
    if (digits.startsWith('251') && digits.length == 12) {
      final national = digits.substring(3);
      if (_ethiopianNational.hasMatch(national)) return '+251$national';
    } else if (digits.startsWith('0') && digits.length == 10) {
      final national = digits.substring(1);
      if (_ethiopianNational.hasMatch(national)) return '+251$national';
    } else if (digits.length == 9 && _ethiopianNational.hasMatch(digits)) {
      return '+251$digits';
    }

    // US/Canada (NANP): +1XXXXXXXXXX (11 digits with country code), or the
    // bare 10-digit national number. Area code can't start with 0 or 1,
    // which also keeps this from colliding with Ethiopia's 10-digit local
    // form above (that one always starts with '0').
    if (digits.startsWith('1') && digits.length == 11) {
      final national = digits.substring(1);
      if (_usNational.hasMatch(national)) return '+1$national';
    } else if (digits.length == 10 && _usNational.hasMatch(digits)) {
      return '+1$digits';
    }

    return null;
  }

  static bool isValid(String input) => normalize(input) != null;
}
