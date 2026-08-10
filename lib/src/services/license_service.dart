import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../domain/canonical.dart';
import '../domain/models.dart';

class LicenseService {
  const LicenseService();

  Future<SignedLicense> verify(
    String licenseText,
    String publicKeyPem, {
    DateTime? now,
  }) async {
    final license = SignedLicense.parse(licenseText);
    final current = (now ?? DateTime.now()).toUtc();
    if (license.payload.expiresAt case final expiration?
        when !expiration.isAfter(current)) {
      throw const FormatException('A licença expirou.');
    }
    final publicKeyBytes = _publicKeyBytes(publicKeyPem);
    final algorithm = Ed25519();
    final valid = await algorithm.verify(
      utf8.encode(canonicalize(license.payload.toJson())),
      signature: Signature(
        base64Decode(license.signature),
        publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      ),
    );
    if (!valid) {
      throw const FormatException('A assinatura da licença é inválida.');
    }
    return license;
  }

  List<int> _publicKeyBytes(String pem) {
    final body = pem
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    final der = base64Decode(body);
    if (der.length < 32) throw const FormatException('Chave pública inválida.');
    return der.sublist(der.length - 32);
  }
}
