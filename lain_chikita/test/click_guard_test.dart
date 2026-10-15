import 'package:flutter_test/flutter_test.dart';
import 'package:lain_chikita/logic/click_guard.dart';

void main() {
  test('clics a ritmo humano son válidos', () {
    final guard = ClickGuard();
    // Intervalos irregulares de ~250ms
    final times = [1000, 1250, 1530, 1760, 2050, 2290, 2580, 2800];
    for (final t in times) {
      expect(guard.check(t), ClickVerdict.valid);
    }
    expect(guard.suspiciousClickCount, 0);
  });

  test('clics más rápidos que el intervalo mínimo se rechazan', () {
    final guard = ClickGuard();
    expect(guard.check(1000), ClickVerdict.valid);
    expect(guard.check(1000 + ClickGuard.minClickIntervalMs - 1), ClickVerdict.rejected);
    expect(guard.suspiciousClickCount, 1);
  });

  test('un patrón de autoclicker se penaliza doble', () {
    final guard = ClickGuard();
    // 5 clics exactamente cada 100ms: el 6to ya detecta el patrón
    for (var i = 0; i < 5; i++) {
      expect(guard.check(1000 + i * 100), ClickVerdict.valid);
    }
    expect(guard.check(1500), ClickVerdict.rejected);
    expect(guard.suspiciousClickCount, 2);
  });

  test('al llegar al máximo de clics sospechosos se bloquea, y unblock lo reinicia', () {
    final guard = ClickGuard();
    guard.check(1000);
    ClickVerdict? last;
    for (var i = 0; i < ClickGuard.maxSuspiciousClicks; i++) {
      last = guard.check(1001);
    }
    expect(last, ClickVerdict.triggeredBlock);
    expect(guard.isBlocked, isTrue);
    expect(guard.check(50000), ClickVerdict.rejected);

    guard.unblock();
    expect(guard.isBlocked, isFalse);
    expect(guard.suspiciousClickCount, 0);
    expect(guard.check(60000), ClickVerdict.valid);
  });
}
