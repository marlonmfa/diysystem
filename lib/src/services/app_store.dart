import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';

import '../domain/models.dart';

class AppStore {
  AppStore._(this.rootDirectory);

  final Directory rootDirectory;
  AppState? _state;

  File get _stateFile => File(paths.join(rootDirectory.path, 'state.json'));
  File get _recoveryFile =>
      File(paths.join(rootDirectory.path, 'state.json.bak'));

  static Future<AppStore> open({Directory? directory}) async {
    final root =
        directory ??
        Directory(
          paths.join((await getApplicationSupportDirectory()).path, 'data'),
        );
    return AppStore._(root);
  }

  AppState get state {
    final value = _state;
    if (value == null) {
      throw StateError('O armazenamento ainda não foi carregado.');
    }
    return value;
  }

  Future<AppState> load() async {
    await rootDirectory.create(recursive: true);
    final readableState = await _stateFile.exists()
        ? _stateFile
        : await _recoveryFile.exists()
        ? _recoveryFile
        : null;
    if (readableState != null) {
      _state = AppState.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(await readableState.readAsString()) as Map,
        ),
      );
    } else {
      final now = DateTime.now().toUtc();
      _state = AppState(
        installationId: _installationId(),
        installedAt: now,
        lastSeenAt: now,
      );
      await save();
    }
    final current = DateTime.now().toUtc();
    if (current.isBefore(state.lastSeenAt)) {
      audit('security.clock_rollback', 'O relógio do aparelho retrocedeu.');
    }
    state.lastSeenAt = current;
    await save();
    return state;
  }

  Future<void> save() async {
    await rootDirectory.create(recursive: true);
    final temporary = File('${_stateFile.path}.tmp');
    await temporary.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(state.toJson())}\n',
      flush: true,
    );
    if (await _stateFile.exists()) {
      if (await _recoveryFile.exists()) await _recoveryFile.delete();
      await _stateFile.rename(_recoveryFile.path);
    }
    try {
      await temporary.rename(_stateFile.path);
      if (await _recoveryFile.exists()) await _recoveryFile.delete();
    } catch (_) {
      if (!await _stateFile.exists() && await _recoveryFile.exists()) {
        await _recoveryFile.rename(_stateFile.path);
      }
      rethrow;
    }
  }

  Future<void> backupManifest(SystemManifest manifest) async {
    final directory = Directory(paths.join(rootDirectory.path, 'backups'));
    await directory.create(recursive: true);
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final file = File(
      paths.join(
        directory.path,
        'manifest-r${manifest.revision}-$timestamp.json',
      ),
    );
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
    );
  }

  void audit(String action, String detail) {
    state.audit.add(
      AuditEntry(
        at: DateTime.now().toUtc(),
        action: action,
        detail: detail.length > 500 ? detail.substring(0, 500) : detail,
      ),
    );
    if (state.audit.length > 500) {
      state.audit.removeRange(0, state.audit.length - 500);
    }
  }

  String _installationId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
