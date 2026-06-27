import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

// Servicio de hashing de contraseñas para manejar el almacenamiento seguro y la verificación de contraseñas.
class PasswordHasher {
  static const int _iterations = 120000;
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  PasswordHasher._();

  static String hash(String password) {
    final salt = _randomBytes(_saltLength);
    final derivedKey = _pbkdf2(password, salt, _iterations, _keyLength);

    return [
      'pbkdf2',
      _iterations.toString(),
      base64UrlEncode(salt),
      base64UrlEncode(derivedKey),
    ].join(r'$');
  }

  static bool verify(String password, String storedValue) {
    final parts = storedValue.split(r'$');

    if (parts.length != 4 || parts.first != 'pbkdf2') {
      return storedValue == password;
    }

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;

    final salt = base64Url.decode(parts[2]);
    final expected = base64Url.decode(parts[3]);
    final actual = _pbkdf2(password, salt, iterations, expected.length);

    return _constantTimeEquals(actual, expected);
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static List<int> _pbkdf2(
    String password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final blocks = <int>[];
    var blockIndex = 1;

    while (blocks.length < keyLength) {
      final block = _block(hmac, salt, iterations, blockIndex);
      blocks.addAll(block);
      blockIndex++;
    }

    return blocks.take(keyLength).toList(growable: false);
  }

  static List<int> _block(
    Hmac hmac,
    List<int> salt,
    int iterations,
    int blockIndex,
  ) {
    final indexBytes = [
      (blockIndex >> 24) & 0xff,
      (blockIndex >> 16) & 0xff,
      (blockIndex >> 8) & 0xff,
      blockIndex & 0xff,
    ];

    var previous = hmac.convert([...salt, ...indexBytes]).bytes;
    final output = List<int>.from(previous);

    for (var i = 1; i < iterations; i++) {
      previous = hmac.convert(previous).bytes;
      for (var j = 0; j < output.length; j++) {
        output[j] ^= previous[j];
      }
    }

    return output;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }
}
