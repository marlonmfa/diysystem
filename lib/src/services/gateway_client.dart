import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models.dart';

class GatewayException implements Exception {
  const GatewayException(this.message);
  final String message;

  @override
  String toString() => message;
}

class GatewayClient {
  GatewayClient({String? baseUrl, http.Client? client})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'DIY_GATEWAY_URL',
            defaultValue: 'http://127.0.0.1:8787',
          ),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<AgentTurn> agentTurn({
    required AppState state,
    required String answer,
  }) async {
    final response = await _post('/api/agent/turn', {
      'auth': {
        'installationId': state.installationId,
        if (state.license != null) 'license': state.license!.toJson(),
      },
      'answer': answer,
      'conversation': state.conversation
          .map((message) => {'role': message.role.name, 'text': message.text})
          .toList(),
      if (state.manifest != null) 'manifest': state.manifest!.toJson(),
    });
    return AgentTurn.fromJson(response);
  }

  Future<Entitlement> entitlement(AppState state) async {
    final response = await _post('/api/license/status', {
      'auth': {
        'installationId': state.installationId,
        if (state.license != null) 'license': state.license!.toJson(),
      },
    });
    return Entitlement.fromJson(
      Map<String, dynamic>.from(response['entitlement'] as Map),
    );
  }

  Future<Map<String, dynamic>> _post(
    String route,
    Map<String, dynamic> body,
  ) async {
    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl$route'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      throw const GatewayException(
        'Não foi possível alcançar o gateway. Confira a conexão e o endereço configurado.',
      );
    }
    final payload = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GatewayException(
        payload['error'] as String? ?? 'O gateway recusou a solicitação.',
      );
    }
    return payload;
  }
}
