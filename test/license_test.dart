import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:diy_system/src/domain/canonical.dart';
import 'package:diy_system/src/services/license_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aceita licença Ed25519 e rejeita adulteração', () async {
    final algorithm = Ed25519();
    final keys = await algorithm.newKeyPair();
    final publicKey = await keys.extractPublicKey();
    final payload = {
      'schemaVersion': 1,
      'id': 'DIY-MINI-0001-1234567890ABCDEF',
      'tier': 'mini',
      'status': 'active',
      'issuedAt': '2026-08-06T12:00:00.000Z',
      'expiresAt': null,
      'maxDevices': 1,
    };
    final signature = await algorithm.sign(
      utf8.encode(canonicalize(payload)),
      keyPair: keys,
    );
    final license = {
      'payload': payload,
      'signature': base64Encode(signature.bytes),
    };
    final pem = _publicPem(publicKey.bytes);
    final service = LicenseService();

    expect(
      (await service.verify(jsonEncode(license), pem)).payload.tier,
      'mini',
    );
    license['payload'] = {...payload, 'tier': 'normal'};
    await expectLater(
      service.verify(jsonEncode(license), pem),
      throwsFormatException,
    );
  });
}

String _publicPem(List<int> key) {
  const prefix = [
    0x30,
    0x2a,
    0x30,
    0x05,
    0x06,
    0x03,
    0x2b,
    0x65,
    0x70,
    0x03,
    0x21,
    0x00,
  ];
  final encoded = base64Encode([...prefix, ...key]);
  return '-----BEGIN PUBLIC KEY-----\n$encoded\n-----END PUBLIC KEY-----\n';
}
