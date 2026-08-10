import 'dart:convert';

enum FieldType { text, textarea, number, date, checkbox, email, phone }

T _required<T>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! T) {
    throw FormatException('Campo "$key" ausente ou inválido.');
  }
  return value;
}

String _boundedString(
  Map<String, dynamic> json,
  String key, {
  int min = 0,
  int max = 10000,
}) {
  final value = _required<String>(json, key).trim();
  if (value.length < min || value.length > max) {
    throw FormatException(
      'Campo "$key" deve ter entre $min e $max caracteres.',
    );
  }
  return value;
}

class FieldDefinition {
  const FieldDefinition({
    required this.id,
    required this.label,
    required this.type,
    required this.required,
    this.helpText,
  });

  final String id;
  final String label;
  final FieldType type;
  final bool required;
  final String? helpText;

  factory FieldDefinition.fromJson(Map<String, dynamic> json) {
    final id = _boundedString(json, 'id', min: 2, max: 49);
    if (!RegExp(r'^[a-z][a-z0-9_]{1,48}$').hasMatch(id)) {
      throw const FormatException('Identificador de campo inválido.');
    }
    final typeName = _required<String>(json, 'type');
    final type = FieldType.values
        .where((value) => value.name == typeName)
        .firstOrNull;
    if (type == null) {
      throw FormatException('Tipo de campo desconhecido: $typeName.');
    }
    final helpText = json['helpText'];
    if (helpText != null && helpText is! String) {
      throw const FormatException('Ajuda do campo inválida.');
    }
    return FieldDefinition(
      id: id,
      label: _boundedString(json, 'label', min: 1, max: 80),
      type: type,
      required: _required<bool>(json, 'required'),
      helpText: (helpText as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.name,
    'required': required,
    if (helpText != null && helpText!.isNotEmpty) 'helpText': helpText,
  };
}

class ScreenDefinition {
  const ScreenDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.singularLabel,
    required this.fields,
  });

  final String id;
  final String title;
  final String description;
  final String singularLabel;
  final List<FieldDefinition> fields;

  factory ScreenDefinition.fromJson(Map<String, dynamic> json) {
    final id = _boundedString(json, 'id', min: 2, max: 49);
    if (!RegExp(r'^[a-z][a-z0-9_]{1,48}$').hasMatch(id)) {
      throw const FormatException('Identificador de tela inválido.');
    }
    final rawFields = _required<List<dynamic>>(json, 'fields');
    if (rawFields.isEmpty || rawFields.length > 30) {
      throw const FormatException('Cada tela precisa ter de 1 a 30 campos.');
    }
    return ScreenDefinition(
      id: id,
      title: _boundedString(json, 'title', min: 1, max: 80),
      description: _boundedString(json, 'description', max: 300),
      singularLabel: _boundedString(json, 'singularLabel', min: 1, max: 60),
      fields: rawFields
          .map(
            (value) => FieldDefinition.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'singularLabel': singularLabel,
    'fields': fields.map((field) => field.toJson()).toList(),
  };
}

class SystemManifest {
  const SystemManifest({
    required this.revision,
    required this.name,
    required this.purpose,
    required this.screens,
  });

  final int revision;
  final String name;
  final String purpose;
  final List<ScreenDefinition> screens;

  factory SystemManifest.fromJson(Map<String, dynamic> json) {
    if (_required<num>(json, 'schemaVersion').toInt() != 1) {
      throw const FormatException('Versão de manifesto incompatível.');
    }
    final revision = _required<num>(json, 'revision').toInt();
    if (revision < 1) throw const FormatException('Revisão inválida.');
    final rawScreens = _required<List<dynamic>>(json, 'screens');
    if (rawScreens.isEmpty || rawScreens.length > 20) {
      throw const FormatException('O sistema precisa ter de 1 a 20 telas.');
    }
    final screens = rawScreens
        .map(
          (value) => ScreenDefinition.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList(growable: false);
    if (screens.map((screen) => screen.id).toSet().length != screens.length) {
      throw const FormatException(
        'Existem identificadores de tela duplicados.',
      );
    }
    return SystemManifest(
      revision: revision,
      name: _boundedString(json, 'name', min: 2, max: 80),
      purpose: _boundedString(json, 'purpose', min: 10, max: 500),
      screens: screens,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'revision': revision,
    'name': name,
    'purpose': purpose,
    'screens': screens.map((screen) => screen.toJson()).toList(),
  };
}

class AdminCredential {
  const AdminCredential({
    required this.name,
    required this.email,
    required this.salt,
    required this.passwordHash,
    required this.iterations,
  });

  final String name;
  final String email;
  final String salt;
  final String passwordHash;
  final int iterations;

  factory AdminCredential.fromJson(Map<String, dynamic> json) =>
      AdminCredential(
        name: _required<String>(json, 'name'),
        email: _required<String>(json, 'email'),
        salt: _required<String>(json, 'salt'),
        passwordHash: _required<String>(json, 'passwordHash'),
        iterations: _required<num>(json, 'iterations').toInt(),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'salt': salt,
    'passwordHash': passwordHash,
    'iterations': iterations,
  };
}

class StoredRecord {
  const StoredRecord({
    required this.id,
    required this.screenId,
    required this.createdAt,
    required this.updatedAt,
    required this.values,
  });

  final String id;
  final String screenId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, Object?> values;

  factory StoredRecord.fromJson(Map<String, dynamic> json) => StoredRecord(
    id: _required<String>(json, 'id'),
    screenId: _required<String>(json, 'screenId'),
    createdAt: DateTime.parse(_required<String>(json, 'createdAt')),
    updatedAt: DateTime.parse(_required<String>(json, 'updatedAt')),
    values: Map<String, Object?>.from(
      _required<Map<String, dynamic>>(json, 'values'),
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'screenId': screenId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'values': values,
  };
}

enum MessageRole { agent, user }

class ConversationMessage {
  const ConversationMessage({
    required this.role,
    required this.text,
    required this.at,
  });

  final MessageRole role;
  final String text;
  final DateTime at;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      ConversationMessage(
        role: MessageRole.values.byName(_required<String>(json, 'role')),
        text: _required<String>(json, 'text'),
        at: DateTime.parse(_required<String>(json, 'at')),
      );

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'text': text,
    'at': at.toUtc().toIso8601String(),
  };
}

class AuditEntry {
  const AuditEntry({
    required this.at,
    required this.action,
    required this.detail,
  });

  final DateTime at;
  final String action;
  final String detail;

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
    at: DateTime.parse(_required<String>(json, 'at')),
    action: _required<String>(json, 'action'),
    detail: _required<String>(json, 'detail'),
  );

  Map<String, dynamic> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'action': action,
    'detail': detail,
  };
}

class LicensePayload {
  const LicensePayload({
    required this.id,
    required this.tier,
    required this.issuedAt,
    required this.expiresAt,
    required this.maxDevices,
  });

  final String id;
  final String tier;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final int maxDevices;

  factory LicensePayload.fromJson(Map<String, dynamic> json) {
    if (_required<num>(json, 'schemaVersion').toInt() != 1 ||
        _required<String>(json, 'status') != 'active') {
      throw const FormatException('Licença incompatível ou inativa.');
    }
    final tier = _required<String>(json, 'tier');
    if (tier != 'mini' && tier != 'normal') {
      throw const FormatException('Nível de licença inválido.');
    }
    return LicensePayload(
      id: _required<String>(json, 'id'),
      tier: tier,
      issuedAt: DateTime.parse(_required<String>(json, 'issuedAt')),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      maxDevices: _required<num>(json, 'maxDevices').toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'tier': tier,
    'status': 'active',
    'issuedAt': issuedAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'maxDevices': maxDevices,
  };
}

class SignedLicense {
  const SignedLicense({required this.payload, required this.signature});

  final LicensePayload payload;
  final String signature;

  factory SignedLicense.fromJson(Map<String, dynamic> json) => SignedLicense(
    payload: LicensePayload.fromJson(
      Map<String, dynamic>.from(_required<Map>(json, 'payload')),
    ),
    signature: _required<String>(json, 'signature'),
  );

  factory SignedLicense.parse(String text) => SignedLicense.fromJson(
    Map<String, dynamic>.from(jsonDecode(text) as Map),
  );

  Map<String, dynamic> toJson() => {
    'payload': payload.toJson(),
    'signature': signature,
  };
}

class Entitlement {
  const Entitlement({
    required this.kind,
    required this.tier,
    required this.daysRemaining,
  });

  final String kind;
  final String? tier;
  final int daysRemaining;

  factory Entitlement.fromJson(Map<String, dynamic> json) => Entitlement(
    kind: _required<String>(json, 'kind'),
    tier: json['tier'] as String?,
    daysRemaining: _required<num>(json, 'daysRemaining').toInt(),
  );
}

class AgentTurn {
  const AgentTurn({
    required this.message,
    required this.ready,
    required this.manifest,
    required this.entitlement,
  });

  final String message;
  final bool ready;
  final SystemManifest manifest;
  final Entitlement entitlement;

  factory AgentTurn.fromJson(Map<String, dynamic> json) => AgentTurn(
    message: _required<String>(json, 'message'),
    ready: _required<bool>(json, 'ready'),
    manifest: SystemManifest.fromJson(
      Map<String, dynamic>.from(_required<Map>(json, 'manifest')),
    ),
    entitlement: Entitlement.fromJson(
      Map<String, dynamic>.from(_required<Map>(json, 'entitlement')),
    ),
  );
}

class AppState {
  AppState({
    required this.installationId,
    required this.installedAt,
    required this.lastSeenAt,
    this.admin,
    this.manifest,
    this.license,
    Map<String, List<StoredRecord>>? records,
    List<ConversationMessage>? conversation,
    List<AuditEntry>? audit,
  }) : records = records ?? {},
       conversation = conversation ?? [],
       audit = audit ?? [];

  final String installationId;
  final DateTime installedAt;
  DateTime lastSeenAt;
  AdminCredential? admin;
  SystemManifest? manifest;
  SignedLicense? license;
  final Map<String, List<StoredRecord>> records;
  final List<ConversationMessage> conversation;
  final List<AuditEntry> audit;

  factory AppState.fromJson(Map<String, dynamic> json) {
    final rawRecords = Map<String, dynamic>.from(
      json['records'] as Map? ?? const {},
    );
    return AppState(
      installationId: _required<String>(json, 'installationId'),
      installedAt: DateTime.parse(_required<String>(json, 'installedAt')),
      lastSeenAt: DateTime.parse(_required<String>(json, 'lastSeenAt')),
      admin: json['admin'] == null
          ? null
          : AdminCredential.fromJson(
              Map<String, dynamic>.from(json['admin'] as Map),
            ),
      manifest: json['manifest'] == null
          ? null
          : SystemManifest.fromJson(
              Map<String, dynamic>.from(json['manifest'] as Map),
            ),
      license: json['license'] == null
          ? null
          : SignedLicense.fromJson(
              Map<String, dynamic>.from(json['license'] as Map),
            ),
      records: rawRecords.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map(
                (item) => StoredRecord.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
        ),
      ),
      conversation: (json['conversation'] as List<dynamic>? ?? const [])
          .map(
            (item) => ConversationMessage.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      audit: (json['audit'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                AuditEntry.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'installationId': installationId,
    'installedAt': installedAt.toUtc().toIso8601String(),
    'lastSeenAt': lastSeenAt.toUtc().toIso8601String(),
    'admin': admin?.toJson(),
    'manifest': manifest?.toJson(),
    'license': license?.toJson(),
    'records': records.map(
      (key, value) =>
          MapEntry(key, value.map((record) => record.toJson()).toList()),
    ),
    'conversation': conversation.map((message) => message.toJson()).toList(),
    'audit': audit.map((entry) => entry.toJson()).toList(),
  };
}
