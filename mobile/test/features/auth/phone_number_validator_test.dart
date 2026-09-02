import 'package:ethioserve/features/auth/domain/phone_number_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneNumberValidator.normalize', () {
    test('normalizes local 09 format', () {
      expect(PhoneNumberValidator.normalize('0912345678'), '+251912345678');
    });

    test('normalizes local 07 format', () {
      expect(PhoneNumberValidator.normalize('0712345678'), '+251712345678');
    });

    test('normalizes already-international format with +', () {
      expect(PhoneNumberValidator.normalize('+251912345678'), '+251912345678');
    });

    test('normalizes international format without +', () {
      expect(PhoneNumberValidator.normalize('251912345678'), '+251912345678');
    });

    test('accepts bare 9-digit national number', () {
      expect(PhoneNumberValidator.normalize('912345678'), '+251912345678');
    });

    test('strips formatting characters (spaces, dashes)', () {
      expect(PhoneNumberValidator.normalize('091 234 5678'), '+251912345678');
      expect(PhoneNumberValidator.normalize('091-234-5678'), '+251912345678');
    });

    test('rejects numbers not starting with 7 or 9', () {
      expect(PhoneNumberValidator.normalize('0812345678'), isNull);
    });

    test('rejects too-short input', () {
      expect(PhoneNumberValidator.normalize('123'), isNull);
    });

    test('rejects empty input', () {
      expect(PhoneNumberValidator.normalize(''), isNull);
    });
  });

  group('PhoneNumberValidator.normalize (US)', () {
    test('normalizes bare 10-digit US number', () {
      expect(PhoneNumberValidator.normalize('2025551234'), '+12025551234');
    });

    test('normalizes US number with leading 1', () {
      expect(PhoneNumberValidator.normalize('12025551234'), '+12025551234');
    });

    test('normalizes already-international US format with +', () {
      expect(PhoneNumberValidator.normalize('+12025551234'), '+12025551234');
    });

    test('strips formatting characters (parens, dashes, spaces)', () {
      expect(PhoneNumberValidator.normalize('(202) 555-1234'), '+12025551234');
    });

    test('rejects a US number with an area code starting with 0 or 1', () {
      expect(PhoneNumberValidator.normalize('0205551234'), isNull);
      expect(PhoneNumberValidator.normalize('11025551234'), isNull);
    });
  });

  group('PhoneNumberValidator.isValid', () {
    test('true for a valid number', () {
      expect(PhoneNumberValidator.isValid('0912345678'), isTrue);
    });

    test('false for an invalid number', () {
      expect(PhoneNumberValidator.isValid('abc'), isFalse);
    });
  });
}
