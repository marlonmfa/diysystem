import 'dart:io';

import 'package:diy_system/src/services/app_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persiste o identificador local com escrita recuperável', () async {
    final directory = await Directory.systemTemp.createTemp(
      'diy-system-store-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final first = await AppStore.open(directory: directory);
    final state = await first.load();
    first.audit('test.saved', 'registro de teste');
    await first.save();

    final reopened = await AppStore.open(directory: directory);
    final restored = await reopened.load();
    expect(restored.installationId, state.installationId);
    expect(restored.audit.any((entry) => entry.action == 'test.saved'), isTrue);
  });
}
