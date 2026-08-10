import 'package:diy_system/src/domain/trial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('permite sete dias a partir do primeiro uso', () {
    final start = DateTime.parse('2026-08-01T00:00:00.000Z');
    expect(
      trialIsActive(start, DateTime.parse('2026-08-07T23:59:59.000Z')),
      isTrue,
    );
    expect(
      trialIsActive(start, DateTime.parse('2026-08-08T00:00:00.000Z')),
      isFalse,
    );
  });

  test('bloqueia retrocesso de relógio', () {
    expect(
      trialDaysRemaining(
        DateTime.parse('2026-08-02T00:00:00.000Z'),
        DateTime.parse('2026-08-01T00:00:00.000Z'),
      ),
      0,
    );
  });
}
