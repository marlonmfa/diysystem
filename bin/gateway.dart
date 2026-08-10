import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:diy_system/src/domain/models.dart';
import 'package:diy_system/src/domain/trial.dart';
import 'package:diy_system/src/services/license_service.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as paths;

final _licenseService = LicenseService();
final _http = http.Client();
final _environment = {..._dotEnv(), ...Platform.environment};
final _statePath =
    _environment['DIY_GATEWAY_STATE_PATH'] ??
    paths.join('var', 'gateway-state.json');
final _publicKeyPath =
    _environment['DIY_LICENSE_PUBLIC_KEY'] ??
    paths.join('config', 'license-public.pem');

Future<void> main() async {
  final host = InternetAddress(_environment['GATEWAY_HOST'] ?? '127.0.0.1');
  final port = int.tryParse(_environment['GATEWAY_PORT'] ?? '') ?? 8787;
  final server = await HttpServer.bind(host, port);
  stdout.writeln('DIY Gateway disponível em http://${host.address}:$port');
  await for (final request in server) {
    unawaited(_handle(request));
  }
}

Future<void> _handle(HttpRequest request) async {
  try {
    if (request.method == 'GET' && request.uri.path == '/health') {
      return _send(request.response, HttpStatus.ok, {
        'ok': true,
        'openaiConfigured': (_environment['OPENAI_API_KEY'] ?? '').isNotEmpty,
      });
    }
    if (request.method != 'POST') {
      throw const HttpProblem(HttpStatus.notFound, 'Rota não encontrada.');
    }
    final body = await _jsonBody(request);
    final entitlement = await _authorize(
      Map<String, dynamic>.from(body['auth'] as Map? ?? const {}),
    );

    if (request.uri.path == '/api/license/status') {
      return _send(request.response, HttpStatus.ok, {
        'entitlement': entitlement.toJson(),
      });
    }
    if (request.uri.path == '/api/agent/turn') {
      final answer = (body['answer'] as String? ?? '').trim();
      if (answer.length < 2 || answer.length > 5000) {
        throw const HttpProblem(
          HttpStatus.badRequest,
          'A resposta deve ter entre 2 e 5.000 caracteres.',
        );
      }
      final current = body['manifest'] == null
          ? null
          : SystemManifest.fromJson(
              Map<String, dynamic>.from(body['manifest'] as Map),
            );
      final conversation = (body['conversation'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .take(60)
          .toList();
      final turn = await _agentTurn(
        conversation: conversation,
        current: current,
        tier: entitlement.tier ?? 'mini',
      );
      return _send(request.response, HttpStatus.ok, {
        ...turn,
        'entitlement': entitlement.toJson(),
      });
    }
    throw const HttpProblem(HttpStatus.notFound, 'Rota não encontrada.');
  } on HttpProblem catch (error) {
    _send(request.response, error.status, {'error': error.message});
  } on FormatException catch (error) {
    _send(request.response, HttpStatus.badRequest, {'error': error.message});
  } catch (error, stack) {
    stderr.writeln(error);
    stderr.writeln(stack);
    _send(request.response, HttpStatus.internalServerError, {
      'error': 'Erro interno do gateway.',
    });
  }
}

Future<Map<String, dynamic>> _jsonBody(HttpRequest request) async {
  final bytes = <int>[];
  await for (final chunk in request) {
    bytes.addAll(chunk);
    if (bytes.length > 1000000) {
      throw const HttpProblem(
        HttpStatus.requestEntityTooLarge,
        'Requisição maior que 1 MB.',
      );
    }
  }
  try {
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
  } catch (_) {
    throw const HttpProblem(HttpStatus.badRequest, 'JSON inválido.');
  }
}

void _send(HttpResponse response, int status, Map<String, dynamic> body) {
  response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
    ..headers.set('x-content-type-options', 'nosniff')
    ..write(jsonEncode(body))
    ..close();
}

Future<GatewayEntitlement> _authorize(Map<String, dynamic> request) async {
  final installationId = request['installationId'] as String? ?? '';
  if (installationId.length < 16) {
    throw const HttpProblem(
      HttpStatus.forbidden,
      'Identificador de instalação inválido.',
    );
  }
  final state = await _loadGatewayState();
  final now = DateTime.now().toUtc();
  if (request['license'] != null) {
    final publicKey = await File(_publicKeyPath).readAsString();
    final license = await _licenseService.verify(
      jsonEncode(request['license']),
      publicKey,
      now: now,
    );
    final activations = List<String>.from(
      state.activations[license.payload.id] ?? const [],
    );
    if (!activations.contains(installationId)) {
      if (activations.length >= license.payload.maxDevices) {
        throw const HttpProblem(
          HttpStatus.forbidden,
          'Esta licença atingiu o limite de dispositivos.',
        );
      }
      activations.add(installationId);
      state.activations[license.payload.id] = activations;
      await _saveGatewayState(state);
    }
    return GatewayEntitlement(
      kind: 'license',
      tier: license.payload.tier,
      daysRemaining: 0,
    );
  }
  final existing = state.trials[installationId];
  final firstSeen = existing == null
      ? now
      : DateTime.parse(existing['firstSeenAt']!);
  if (!trialIsActive(firstSeen, now)) {
    throw const HttpProblem(
      HttpStatus.forbidden,
      'O período de avaliação de 7 dias terminou.',
    );
  }
  state.trials[installationId] = {
    'firstSeenAt': firstSeen.toIso8601String(),
    'lastSeenAt': now.toIso8601String(),
  };
  await _saveGatewayState(state);
  return GatewayEntitlement(
    kind: 'trial',
    tier: 'mini',
    daysRemaining: trialDaysRemaining(firstSeen, now),
  );
}

Future<Map<String, dynamic>> _agentTurn({
  required List<Map<String, dynamic>> conversation,
  required SystemManifest? current,
  required String tier,
}) async {
  final apiKey = _environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw const HttpProblem(
      HttpStatus.internalServerError,
      'OPENAI_API_KEY não configurada no gateway.',
    );
  }
  final revision = (current?.revision ?? 0) + 1;
  final response = await _http
      .post(
        Uri.parse('https://api.openai.com/v1/responses'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $apiKey',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode({
          'model': tier == 'normal'
              ? _environment['OPENAI_MODEL_NORMAL'] ?? 'gpt-5.6-sol'
              : _environment['OPENAI_MODEL_MINI'] ?? 'gpt-5.6-terra',
          'store': false,
          'reasoning': {'effort': 'low'},
          'instructions': [
            'Você é o arquiteto conversacional de um sistema administrativo local.',
            'A cada resposta, atualize uma versão operável do sistema e faça exatamente uma próxima pergunta em português.',
            'Pergunte progressivamente sobre objetivo, usuários, dados, fluxos, regras de acesso, relatórios e integrações.',
            'Preserve tudo que não precisa mudar. Não crie campos de senha, tokens, segredos ou código executável.',
            'O manifesto deve ter revisão $revision. Use ids snake_case sem acentos.',
            'Defina ready como true quando já houver contexto suficiente para uso real, mas continue aceitando melhorias.',
            'Responda estritamente conforme o JSON Schema.',
          ].join(' '),
          'input': [
            if (current != null)
              'Manifesto atual:\n${jsonEncode(current.toJson())}',
            'Conversa:\n${jsonEncode(conversation)}',
          ].join('\n\n'),
          'text': {
            'format': {
              'type': 'json_schema',
              'name': 'agent_turn',
              'strict': true,
              'schema': _agentTurnSchema,
            },
          },
        }),
      )
      .timeout(const Duration(seconds: 90));
  final payload = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final apiError = payload['error'] as Map?;
    throw HttpProblem(
      HttpStatus.badGateway,
      apiError?['message'] as String? ?? 'A OpenAI recusou a solicitação.',
    );
  }
  final outputText = _responseText(payload);
  final result = Map<String, dynamic>.from(jsonDecode(outputText) as Map);
  final manifest = SystemManifest.fromJson(
    Map<String, dynamic>.from(result['manifest'] as Map),
  );
  if (manifest.revision != revision) {
    throw const HttpProblem(
      HttpStatus.badGateway,
      'O agente retornou uma revisão incompatível.',
    );
  }
  final message = result['message'] as String? ?? '';
  if (message.trim().length < 5) {
    throw const HttpProblem(
      HttpStatus.badGateway,
      'O agente não retornou a próxima pergunta.',
    );
  }
  return {
    'message': message,
    'ready': result['ready'] == true,
    'manifest': manifest.toJson(),
  };
}

String _responseText(Map<String, dynamic> response) {
  for (final output in response['output'] as List<dynamic>? ?? const []) {
    final item = output as Map<String, dynamic>;
    for (final content in item['content'] as List<dynamic>? ?? const []) {
      final part = content as Map<String, dynamic>;
      if (part['type'] == 'output_text' && part['text'] is String) {
        return part['text'] as String;
      }
    }
  }
  throw const HttpProblem(
    HttpStatus.badGateway,
    'A IA não retornou uma resposta estruturada.',
  );
}

Future<_GatewayState> _loadGatewayState() async {
  final file = File(_statePath);
  if (!await file.exists()) return _GatewayState();
  final json = Map<String, dynamic>.from(
    jsonDecode(await file.readAsString()) as Map,
  );
  return _GatewayState(
    trials: Map<String, Map<String, String>>.fromEntries(
      Map<String, dynamic>.from(json['trials'] as Map? ?? const {}).entries.map(
        (entry) =>
            MapEntry(entry.key, Map<String, String>.from(entry.value as Map)),
      ),
    ),
    activations: Map<String, List<String>>.fromEntries(
      Map<String, dynamic>.from(
        json['activations'] as Map? ?? const {},
      ).entries.map(
        (entry) => MapEntry(entry.key, List<String>.from(entry.value as List)),
      ),
    ),
  );
}

Future<void> _saveGatewayState(_GatewayState state) async {
  final file = File(_statePath);
  await file.parent.create(recursive: true);
  final temporary = File('${file.path}.tmp');
  await temporary.writeAsString(
    jsonEncode({'trials': state.trials, 'activations': state.activations}),
    flush: true,
  );
  if (await file.exists()) await file.delete();
  await temporary.rename(file.path);
}

Map<String, String> _dotEnv() {
  final file = File('.env');
  if (!file.existsSync()) return const {};
  final values = <String, String>{};
  for (final rawLine in file.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final separator = line.indexOf('=');
    if (separator <= 0) continue;
    final key = line.substring(0, separator).trim();
    var value = line.substring(separator + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    values[key] = value;
  }
  return values;
}

class GatewayEntitlement {
  const GatewayEntitlement({
    required this.kind,
    required this.tier,
    required this.daysRemaining,
  });
  final String kind;
  final String? tier;
  final int daysRemaining;
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'tier': tier,
    'daysRemaining': daysRemaining,
  };
}

class _GatewayState {
  _GatewayState({
    Map<String, Map<String, String>>? trials,
    Map<String, List<String>>? activations,
  }) : trials = trials ?? {},
       activations = activations ?? {};
  final Map<String, Map<String, String>> trials;
  final Map<String, List<String>> activations;
}

class HttpProblem implements Exception {
  const HttpProblem(this.status, this.message);
  final int status;
  final String message;
}

const _fieldSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['id', 'label', 'type', 'required', 'helpText'],
  'properties': {
    'id': {'type': 'string', 'pattern': r'^[a-z][a-z0-9_]{1,48}$'},
    'label': {'type': 'string', 'minLength': 1, 'maxLength': 80},
    'type': {
      'type': 'string',
      'enum': [
        'text',
        'textarea',
        'number',
        'date',
        'checkbox',
        'email',
        'phone',
      ],
    },
    'required': {'type': 'boolean'},
    'helpText': {
      'type': ['string', 'null'],
      'maxLength': 240,
    },
  },
};

const _screenSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['id', 'title', 'description', 'singularLabel', 'fields'],
  'properties': {
    'id': {'type': 'string', 'pattern': r'^[a-z][a-z0-9_]{1,48}$'},
    'title': {'type': 'string', 'minLength': 1, 'maxLength': 80},
    'description': {'type': 'string', 'maxLength': 300},
    'singularLabel': {'type': 'string', 'minLength': 1, 'maxLength': 60},
    'fields': {
      'type': 'array',
      'minItems': 1,
      'maxItems': 30,
      'items': _fieldSchema,
    },
  },
};

const _agentTurnSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['message', 'ready', 'manifest'],
  'properties': {
    'message': {'type': 'string', 'minLength': 5, 'maxLength': 800},
    'ready': {'type': 'boolean'},
    'manifest': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['schemaVersion', 'revision', 'name', 'purpose', 'screens'],
      'properties': {
        'schemaVersion': {'type': 'integer', 'const': 1},
        'revision': {'type': 'integer', 'minimum': 1},
        'name': {'type': 'string', 'minLength': 2, 'maxLength': 80},
        'purpose': {'type': 'string', 'minLength': 10, 'maxLength': 500},
        'screens': {
          'type': 'array',
          'minItems': 1,
          'maxItems': 20,
          'items': _screenSchema,
        },
      },
    },
  },
};
