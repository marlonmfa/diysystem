import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:diy_system/src/domain/canonical.dart';
import 'package:path/path.dart' as paths;

final _algorithm = Ed25519();
final _random = Random.secure();

Future<void> main() async {
  final licensesDirectory = Directory(paths.join('var', 'licenses'));
  final indexFile = File(paths.join(licensesDirectory.path, 'index.csv'));
  if (await indexFile.exists()) {
    final entries = (await indexFile.readAsLines()).length - 1;
    if (entries != 2000) {
      throw StateError(
        'Inventário existente incompleto: $entries de 2000 licenças.',
      );
    }
    stdout.writeln(
      'O lote já existe: 1000 MINI + 1000 NORMAL. Nada foi sobrescrito.',
    );
    return;
  }

  final keys = await _issuerKeys();
  await licensesDirectory.create(recursive: true);
  final index = <String>['id,tier,file'];
  for (final tier in ['mini', 'normal']) {
    final directory = Directory(paths.join(licensesDirectory.path, tier));
    await directory.create(recursive: true);
    for (var sequence = 1; sequence <= 1000; sequence += 1) {
      final id =
          'DIY-${tier.toUpperCase()}-${sequence.toString().padLeft(4, '0')}-${_hex(12)}';
      final payload = {
        'schemaVersion': 1,
        'id': id,
        'tier': tier,
        'status': 'active',
        'issuedAt': DateTime.now().toUtc().toIso8601String(),
        'expiresAt': null,
        'maxDevices': 1,
      };
      final signature = await _algorithm.sign(
        utf8.encode(canonicalize(payload)),
        keyPair: keys,
      );
      final fileName = '$id.json';
      await File(paths.join(directory.path, fileName)).writeAsString(
        '${const JsonEncoder.withIndent('  ').convert({'payload': payload, 'signature': base64Encode(signature.bytes)})}\n',
      );
      index.add('$id,$tier,$tier/$fileName');
    }
  }
  await indexFile.writeAsString('${index.join('\n')}\n');
  stdout.writeln('Licenças geradas: 1000 MINI + 1000 NORMAL.');
}

Future<SimpleKeyPairData> _issuerKeys() async {
  final privateFile = File(paths.join('var', 'issuer', 'private-key.pem'));
  final publicFile = File(paths.join('config', 'license-public.pem'));
  if (await privateFile.exists() && await publicFile.exists()) {
    final seed = _pemBytes(
      await privateFile.readAsString(),
    ).sublist(_pemBytes(await privateFile.readAsString()).length - 32);
    final publicBytes = _pemBytes(
      await publicFile.readAsString(),
    ).sublist(_pemBytes(await publicFile.readAsString()).length - 32);
    return SimpleKeyPairData(
      seed,
      publicKey: SimplePublicKey(publicBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
  }
  final pair = await _algorithm.newKeyPair();
  final data = await pair.extract();
  final publicKey = await data.extractPublicKey();
  await privateFile.parent.create(recursive: true);
  await publicFile.parent.create(recursive: true);
  await privateFile.writeAsString(
    _pem('PRIVATE KEY', [..._privatePrefix, ...data.bytes]),
  );
  await publicFile.writeAsString(
    _pem('PUBLIC KEY', [..._publicPrefix, ...publicKey.bytes]),
  );
  return data;
}

List<int> _pemBytes(String value) => base64Decode(
  value
      .replaceAll(RegExp(r'-----BEGIN [^-]+-----'), '')
      .replaceAll(RegExp(r'-----END [^-]+-----'), '')
      .replaceAll(RegExp(r'\s'), ''),
);

String _pem(String label, List<int> bytes) {
  final encoded = base64Encode(bytes);
  final lines = <String>[];
  for (var offset = 0; offset < encoded.length; offset += 64) {
    lines.add(encoded.substring(offset, min(offset + 64, encoded.length)));
  }
  return '-----BEGIN $label-----\n${lines.join('\n')}\n-----END $label-----\n';
}

String _hex(int bytes) => List.generate(
  bytes,
  (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
).join().toUpperCase();

const _privatePrefix = [
  0x30,
  0x2e,
  0x02,
  0x01,
  0x00,
  0x30,
  0x05,
  0x06,
  0x03,
  0x2b,
  0x65,
  0x70,
  0x04,
  0x22,
  0x04,
  0x20,
];
const _publicPrefix = [
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
