import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_feed/session_controller.dart';

import 'fake_session_platform.dart';

void main() {
  test(
    'initialization restores the native session and installed app catalog',
    () async {
      final native = FakeSessionPlatform();
      native.progress['rewardSeconds'] = 312;
      native.progress['focusByDay'] = {'2026-10-13': 1500};
      native.progress['session']['phase'] = 'paused';
      native.progress['session']['focusRemainingSeconds'] = 900;
      final c = SessionController(
        platform: native,
        now: () => DateTime(2026, 10, 13),
        poll: false,
      );
      await c.initialize();
      expect(c.state!.balance, 312);
      expect(c.state!.phase, 'paused');
      expect(c.state!.focusRemaining, 900);
      expect(c.focusToday, 1500);
      expect(c.apps.length, 2);
      c.dispose();
    },
  );
  test('zero balance never calls the native reward method', () async {
    final native = FakeSessionPlatform();
    final c = SessionController(platform: native, poll: false);
    await c.initialize();
    await c.reward(1);
    expect(native.calls, isNot(contains('reward')));
    expect(c.error, contains('Saldo insuficiente'));
    c.dispose();
  });
  test('duplicate taps cannot create two sessions', () async {
    final native = FakeSessionPlatform();
    final c = SessionController(platform: native, poll: false);
    await c.initialize();
    await Future.wait([c.start(), c.start()]);
    expect(native.calls.where((v) => v == 'start').length, 1);
    c.dispose();
  });
  test('stale status cannot overwrite a newer command response', () async {
    final native = FakeSessionPlatform();
    final c = SessionController(platform: native, poll: false);
    await c.initialize();
    final old = native.response;
    native.delayedStatus = Completer<dynamic>();
    final refresh = c.refresh();
    native.progress['session']['phase'] = 'focus';
    native.monitor = true;
    await c.start();
    native.delayedStatus!.complete(old);
    await refresh;
    expect(c.state!.phase, 'focus');
    expect(c.state!.blocking, isTrue);
    c.dispose();
  });
  test(
    'failed storage action leaves the last accepted balance unchanged',
    () async {
      final native = FakeSessionPlatform();
      native.progress['rewardSeconds'] = 300;
      final c = SessionController(platform: native, poll: false);
      await c.initialize();
      native.fail = 'reward';
      await c.reward(60);
      expect(c.state!.balance, 300);
      expect(c.error, isNotNull);
      c.dispose();
    },
  );
  test('interrupted native protection is reflected instead of showing active blocking', () async {
    final native = FakeSessionPlatform();
    final c = SessionController(platform: native, poll: false);
    await c.initialize();
    native.progress['session']['phase'] = 'paused';
    native.progress['notice'] = 'Monitor interrompido.';
    await c.refresh();
    expect(c.state!.blocking, isFalse);
    expect(c.state!.notice, contains('interrompido'));
    c.dispose();
  });
  test('leaving the UI does not stop the native session', () async {
    final native = FakeSessionPlatform();
    final c = SessionController(platform: native, poll: false);
    await c.initialize();
    c.dispose();
    expect(native.calls, isNot(contains('stop')));
  });
  test(
    'today totals change without erasing previous days or balance',
    () async {
      var now = DateTime(2026, 10, 13);
      final native = FakeSessionPlatform();
      native.progress['rewardSeconds'] = 12;
      native.progress['focusByDay'] = {'2026-10-13': 60};
      final c = SessionController(
        platform: native,
        now: () => now,
        poll: false,
      );
      await c.initialize();
      expect(c.focusToday, 60);
      now = DateTime(2026, 10, 14);
      expect(c.focusToday, 0);
      expect(c.state!.balance, 12);
      c.dispose();
    },
  );
}
