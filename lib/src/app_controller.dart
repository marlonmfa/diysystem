import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'domain/models.dart';
import 'domain/trial.dart';
import 'services/app_store.dart';
import 'services/auth_service.dart';
import 'services/gateway_client.dart';
import 'services/license_service.dart';

enum AppPhase { loading, setup, login, studio, system }

class AppController extends ChangeNotifier {
  AppController({
    required AppStore store,
    GatewayClient? gateway,
    AuthService? auth,
    LicenseService? licenses,
  }) : _store = store,
       _gateway = gateway ?? GatewayClient(),
       _auth = auth ?? AuthService(),
       _licenses = licenses ?? const LicenseService();

  final AppStore _store;
  final GatewayClient _gateway;
  final AuthService _auth;
  final LicenseService _licenses;

  AppPhase phase = AppPhase.loading;
  bool busy = false;
  bool authenticated = false;
  String? error;
  Entitlement? entitlement;

  AppState get state => _store.state;
  SystemManifest? get manifest => state.manifest;

  Future<void> initialize() async {
    await _store.load();
    entitlement = _localEntitlement();
    phase = state.admin == null ? AppPhase.setup : AppPhase.login;
    notifyListeners();
    try {
      entitlement = await _gateway.entitlement(state);
    } catch (_) {
      // O sistema local continua utilizável mesmo quando a IA está desconectada.
    }
    notifyListeners();
  }

  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    if (password != confirmation) {
      return _setError('As senhas não coincidem.');
    }
    await _run(() async {
      if (state.admin != null) {
        throw const FormatException('O administrador já foi criado.');
      }
      state.admin = await _auth.createCredential(
        name: name,
        email: email,
        password: password,
      );
      authenticated = true;
      _ensureFirstQuestion();
      _store.audit('admin.created', state.admin!.email);
      await _store.save();
      phase = AppPhase.studio;
    });
  }

  Future<void> login(String email, String password) async {
    await _run(() async {
      final admin = state.admin;
      if (admin == null ||
          admin.email != email.trim().toLowerCase() ||
          !await _auth.passwordMatches(password, admin)) {
        throw const FormatException('E-mail ou senha inválidos.');
      }
      authenticated = true;
      _ensureFirstQuestion();
      _store.audit('admin.login', admin.email);
      await _store.save();
      phase = state.manifest == null ? AppPhase.studio : AppPhase.system;
    });
  }

  Future<void> logout() async {
    authenticated = false;
    _store.audit('admin.logout', state.admin?.email ?? 'administrador');
    await _store.save();
    phase = AppPhase.login;
    notifyListeners();
  }

  void openStudio() {
    if (!authenticated) {
      phase = AppPhase.login;
    } else {
      phase = AppPhase.studio;
    }
    clearError();
  }

  void openSystem() {
    if (state.manifest == null) return;
    phase = AppPhase.system;
    clearError();
  }

  Future<void> sendAnswer(String answer) async {
    final normalized = answer.trim();
    if (normalized.length < 2) {
      return _setError('Escreva um pouco mais para continuar.');
    }
    await _run(() async {
      state.conversation.add(
        ConversationMessage(
          role: MessageRole.user,
          text: normalized,
          at: DateTime.now().toUtc(),
        ),
      );
      await _store.save();
      final turn = await _gateway.agentTurn(state: state, answer: normalized);
      final current = state.manifest;
      if (current != null && turn.manifest.revision != current.revision) {
        if (turn.manifest.revision != current.revision + 1) {
          throw const FormatException(
            'O agente retornou uma revisão incompatível.',
          );
        }
        await _store.backupManifest(current);
      }
      state.manifest = turn.manifest;
      entitlement = turn.entitlement;
      state.conversation.add(
        ConversationMessage(
          role: MessageRole.agent,
          text: turn.message,
          at: DateTime.now().toUtc(),
        ),
      );
      _store.audit(
        current == null ? 'system.created' : 'system.evolved',
        '${turn.manifest.name} · revisão ${turn.manifest.revision}',
      );
      await _store.save();
    });
  }

  Future<void> activateLicense(String text) async {
    await _run(() async {
      final publicKey = await rootBundle.loadString(
        'config/license-public.pem',
      );
      final previous = state.license;
      state.license = await _licenses.verify(text, publicKey);
      try {
        entitlement = await _gateway.entitlement(state);
      } catch (_) {
        state.license = previous;
        rethrow;
      }
      _store.audit('license.activated', state.license!.payload.id);
      await _store.save();
    });
  }

  Future<void> createRecord(
    String screenId,
    Map<String, Object?> values,
  ) async {
    await _run(() async {
      final screen = state.manifest?.screens
          .where((item) => item.id == screenId)
          .firstOrNull;
      if (screen == null) throw const FormatException('Tela desconhecida.');
      final allowed = screen.fields.map((field) => field.id).toSet();
      final sanitized = Map<String, Object?>.fromEntries(
        values.entries.where((entry) => allowed.contains(entry.key)),
      );
      for (final field in screen.fields.where((item) => item.required)) {
        final value = sanitized[field.id];
        if (value == null || value == '') {
          throw FormatException('O campo ${field.label} é obrigatório.');
        }
      }
      final now = DateTime.now().toUtc();
      final record = StoredRecord(
        id: _randomId(),
        screenId: screenId,
        createdAt: now,
        updatedAt: now,
        values: sanitized,
      );
      state.records.putIfAbsent(screenId, () => []).add(record);
      _store.audit('record.created', '$screenId · ${record.id}');
      await _store.save();
    });
  }

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() operation) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await operation();
    } catch (cause) {
      error = cause is GatewayException
          ? cause.message
          : cause is FormatException
          ? cause.message
          : 'Não foi possível concluir esta ação.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _setError(String message) {
    error = message;
    notifyListeners();
  }

  void _ensureFirstQuestion() {
    if (state.conversation.isNotEmpty) return;
    state.conversation.add(
      ConversationMessage(
        role: MessageRole.agent,
        text:
            'Vamos construir isso juntos. Qual é o nome da organização e qual problema principal o sistema precisa resolver?',
        at: DateTime.now().toUtc(),
      ),
    );
  }

  Entitlement _localEntitlement() {
    if (state.license != null) {
      return Entitlement(
        kind: 'license',
        tier: state.license!.payload.tier,
        daysRemaining: 0,
      );
    }
    final active = trialIsActive(state.installedAt);
    return Entitlement(
      kind: active ? 'trial' : 'expired',
      tier: active ? 'mini' : null,
      daysRemaining: active ? trialDaysRemaining(state.installedAt) : 0,
    );
  }

  String _randomId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
