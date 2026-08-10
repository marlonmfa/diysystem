import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../domain/models.dart';

class AuthService {
  static const defaultIterations = 120000;

  Future<AdminCredential> createCredential({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedName.length < 2 || normalizedName.length > 100) {
      throw const FormatException('Informe um nome entre 2 e 100 caracteres.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      throw const FormatException('Informe um e-mail válido.');
    }
    if (password.length < 10 || password.length > 200) {
      throw const FormatException(
        'A senha precisa ter entre 10 e 200 caracteres.',
      );
    }
    final salt = _randomBytes(16);
    final digest = await _pbkdf2(password, salt, defaultIterations);
    return AdminCredential(
      name: normalizedName,
      email: normalizedEmail,
      salt: base64Encode(salt),
      passwordHash: base64Encode(digest),
      iterations: defaultIterations,
    );
  }

  Future<bool> passwordMatches(
    String password,
    AdminCredential credential,
  ) async {
    final candidate = await _pbkdf2(
      password,
      base64Decode(credential.salt),
      credential.iterations,
    );
    final expected = base64Decode(credential.passwordHash);
    if (candidate.length != expected.length) return false;
    var difference = 0;
    for (var index = 0; index < candidate.length; index += 1) {
      difference |= candidate[index] ^ expected[index];
    }
    return difference == 0;
  }

  Future<List<int>> _pbkdf2(
    String password,
    List<int> salt,
    int iterations,
  ) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    final key = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }
}
