import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

void main() {
  const hasher = PasswordHasher();

  // Made by the reference implementation (argon2-cffi 25, libargon2):
  // password 'Clave-de-prueba-ñ', salt 00 01 .. 0f, m=19456 t=2 p=1.
  const reference =
      r'$argon2id$v=19$m=19456,t=2,p=1$AAECAwQFBgcICQoLDA0ODw'
      r'$xfViBWB08DC1DCyYYpfE8Zel6TztIC++D/IMWX0FN6A';

  test('matches the reference implementation (UTF-8 password)', () async {
    expect(await hasher.verify('Clave-de-prueba-ñ', reference), isTrue);
    expect(await hasher.verify('Clave-de-prueba-n', reference), isFalse);
    expect(
      await hasher.hash('Clave-de-prueba-ñ', salt: List.generate(16, (i) => i)),
      reference,
    );
  });

  test('hash → verify; a new random salt each time', () async {
    final a = await hasher.hash('1234');
    final b = await hasher.hash('1234');
    expect(a, startsWith(r'$argon2id$v=19$m=19456,t=2,p=1$'));
    expect(a, isNot(b));
    expect(await hasher.verify('1234', a), isTrue);
    expect(await hasher.verify('1235', a), isFalse);
  });

  test('malformed, other algorithms or absurd costs never match', () async {
    for (final bad in [
      '',
      'x',
      r'$argon2i$v=19$m=19456,t=2,p=1$AAECAwQFBgcICQoLDA0ODw$xfViBWB08DC1DCyYYpfE8Zel6TztIC++D/IMWX0FN6A',
      r'$argon2id$v=16$m=19456,t=2,p=1$AAECAwQFBgcICQoLDA0ODw$xfViBWB08DC1DCyYYpfE8Zel6TztIC++D/IMWX0FN6A',
      r'$argon2id$v=19$m=99999999,t=2,p=1$AAECAwQFBgcICQoLDA0ODw$xfViBWB08DC1DCyYYpfE8Zel6TztIC++D/IMWX0FN6A',
      r'$argon2id$v=19$m=19456,t=2$AAECAwQFBgcICQoLDA0ODw$xfViBWB08DC1DCyYYpfE8Zel6TztIC++D/IMWX0FN6A',
      r'$argon2id$v=19$m=19456,t=2,p=1$!!!$xfViBWB08DC1DCyYYpfE8Zel6TztIC++D/IMWX0FN6A',
      r'$argon2id$v=19$m=19456,t=2,p=1$AAECAwQFBgcICQoLDA0ODw$AAAA',
    ]) {
      expect(
        await hasher.verify('Clave-de-prueba-ñ', bad),
        isFalse,
        reason: bad,
      );
    }
  });

  test('PIN: 4 to 6 digits', () {
    for (final ok in ['1234', '00000', '987654']) {
      expect(isValidPin(ok), isTrue, reason: ok);
    }
    for (final bad in ['', '123', '1234567', '12a4', ' 1234', '١٢٣٤']) {
      expect(isValidPin(bad), isFalse, reason: bad);
    }
  });
}
