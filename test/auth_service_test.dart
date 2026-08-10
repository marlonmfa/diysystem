import 'package:diy_system/src/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('protege e verifica a senha administrativa', () async {
    final service = AuthService();
    final credential = await service.createCredential(
      name: 'Maria Silva',
      email: 'MARIA@example.com',
      password: 'uma-senha-segura',
    );

    expect(credential.email, 'maria@example.com');
    expect(
      await service.passwordMatches('uma-senha-segura', credential),
      isTrue,
    );
    expect(
      await service.passwordMatches('senha-incorreta', credential),
      isFalse,
    );
  });
}
