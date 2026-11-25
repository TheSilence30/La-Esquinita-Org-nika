import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

void main() {
  test('valid RUCs: the store (person) and a company', () {
    expect(isValidRuc('10409288419'), isTrue);
    expect(isValidRuc('20100070970'), isTrue);
  });

  test('wrong check digit, length, prefix or characters', () {
    for (final bad in [
      '10409288418',
      '1040928841',
      '104092884190',
      '30409288419',
      '1040928841a',
      ' 10409288419',
      '',
    ]) {
      expect(isValidRuc(bad), isFalse, reason: bad);
    }
  });
}
