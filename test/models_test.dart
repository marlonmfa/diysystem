import 'package:diy_system/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('valida e serializa um manifesto operacional', () {
    final manifest = SystemManifest.fromJson({
      'schemaVersion': 1,
      'revision': 1,
      'name': 'Oficina Azul',
      'purpose': 'Organizar o atendimento e os serviços da oficina.',
      'screens': [
        {
          'id': 'clientes',
          'title': 'Clientes',
          'description': 'Cadastro local de clientes.',
          'singularLabel': 'Cliente',
          'fields': [
            {
              'id': 'nome',
              'label': 'Nome',
              'type': 'text',
              'required': true,
              'helpText': null,
            },
          ],
        },
      ],
    });

    expect(manifest.name, 'Oficina Azul');
    expect(
      SystemManifest.fromJson(
        manifest.toJson(),
      ).screens.single.fields.single.type,
      FieldType.text,
    );
  });

  test('rejeita identificadores inseguros', () {
    expect(
      () => FieldDefinition.fromJson({
        'id': '../senha',
        'label': 'Senha',
        'type': 'text',
        'required': false,
      }),
      throwsFormatException,
    );
  });
}
