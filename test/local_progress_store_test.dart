import 'package:flutter_test/flutter_test.dart';
import 'package:focus_feed/local_progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'round trip preserves disabled apps, fractional balance and daily history',
    () {
      final original = ProgressData(
        apps: {'Instagram': false, 'TikTok': false, 'YouTube': true},
        rewardSeconds: 312,
        focusByDay: {'2026-10-12': 300, '2026-10-13': 1500},
      );
      final loaded = ProgressData.decode(original.encode());
      expect(loaded.apps, original.apps);
      expect(loaded.rewardSeconds, 312);
      expect(loaded.focusToday(DateTime(2026, 10, 13)), 1500);
      expect(loaded.focusToday(DateTime(2026, 10, 14)), 0);
      expect(loaded.focusByDay['2026-10-12'], 300);
    },
  );
  test('invalid or future data is rejected, not overwritten with defaults', () {
    expect(() => ProgressData.decode('invalid'), throwsFormatException);
    expect(() => ProgressData.decode('{"version":2}'), throwsFormatException);
    expect(
      () => ProgressData.decode(
        '{"version":1,"apps":{},"rewardSeconds":-1,"focusByDay":{}}',
      ),
      throwsFormatException,
    );
    expect(
      () => ProgressData.decode(
        '{"version":1,"apps":{},"rewardSeconds":1,"focusByDay":{"2026-02-30":60}}',
      ),
      throwsFormatException,
    );
  });
}
