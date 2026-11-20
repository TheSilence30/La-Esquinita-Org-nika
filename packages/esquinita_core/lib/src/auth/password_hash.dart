import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Argon2id hashes of passwords and PINs in the PHC string format that other
/// tools also read (argon2-cffi, libsodium):
/// `$argon2id$v=19$m=19456,t=2,p=1$<salt>$<hash>`.
///
/// The server hashes passwords; a device checks a PIN offline against the
/// `pin_hash` it received, so both use this one implementation.
class PasswordHasher {
  /// OWASP minimum for Argon2id: 19 MiB, 2 passes, 1 lane (~90 ms on the PC).
  const PasswordHasher({
    this.memoryKib = 19456,
    this.iterations = 2,
    this.parallelism = 1,
  });

  final int memoryKib;
  final int iterations;
  final int parallelism;

  /// Largest cost accepted when verifying: a tampered hash must not make the
  /// server allocate unbounded memory.
  static const _maxMemoryKib = 262144; // 256 MiB
  static const _maxIterations = 10;

  /// New hash with a random 16-byte salt ([salt] only for tests).
  Future<String> hash(String secret, {List<int>? salt}) async {
    final s = salt ?? _randomBytes(16);
    final out = await _derive(secret, s, memoryKib, iterations, parallelism);
    return '\$argon2id\$v=19\$m=$memoryKib,t=$iterations,p=$parallelism'
        '\$${_b64(s)}\$${_b64(out)}';
  }

  /// Whether [secret] matches [phc]. A malformed or unsupported hash is a
  /// mismatch, never an exception.
  Future<bool> verify(String secret, String phc) async {
    final parsed = _parse(phc);
    if (parsed == null) return false;
    final (m, t, p, salt, expected) = parsed;
    final actual = await _derive(
      secret,
      salt,
      m,
      t,
      p,
      length: expected.length,
    );
    return _constantTimeEquals(actual, expected);
  }

  static Future<List<int>> _derive(
    String secret,
    List<int> salt,
    int m,
    int t,
    int p, {
    int length = 32,
  }) async {
    final key = await Argon2id(
      parallelism: p,
      memory: m,
      iterations: t,
      hashLength: length,
    ).deriveKey(secretKey: SecretKey(utf8.encode(secret)), nonce: salt);
    return key.extractBytes();
  }

  static (int, int, int, List<int>, List<int>)? _parse(String phc) {
    final parts = phc.split(r'$');
    // ['', 'argon2id', 'v=19', 'm=..,t=..,p=..', salt, hash]
    if (parts.length != 6 ||
        parts[0].isNotEmpty ||
        parts[1] != 'argon2id' ||
        parts[2] != 'v=19') {
      return null;
    }
    final params = <String, int>{};
    for (final kv in parts[3].split(',')) {
      final i = kv.indexOf('=');
      final v = i < 0 ? null : int.tryParse(kv.substring(i + 1));
      if (v == null) return null;
      params[kv.substring(0, i)] = v;
    }
    final (m, t, p) = (params['m'], params['t'], params['p']);
    if (m == null || t == null || p == null) return null;
    if (m < 8 * p || m > _maxMemoryKib || t < 1 || t > _maxIterations) {
      return null;
    }
    if (p < 1 || p > 4) return null;
    try {
      final salt = _unb64(parts[4]);
      final hash = _unb64(parts[5]);
      if (salt.length < 8 || hash.length < 16 || hash.length > 64) return null;
      return (m, t, p, salt, hash);
    } on FormatException {
      return null;
    }
  }

  static List<int> _randomBytes(int n) {
    final r = Random.secure();
    return [for (var i = 0; i < n; i++) r.nextInt(256)];
  }

  // PHC uses standard base64 without padding.
  static String _b64(List<int> bytes) =>
      base64.encode(bytes).replaceAll('=', '');

  static List<int> _unb64(String s) =>
      base64.decode(s.padRight((s.length + 3) ~/ 4 * 4, '='));

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// A PIN is 4 to 6 digits, one per user (user decision, 2026-11-19).
bool isValidPin(String pin) => RegExp(r'^[0-9]{4,6}$').hasMatch(pin);
