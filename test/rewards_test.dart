import 'package:flutter_test/flutter_test.dart';
import 'package:focus_feed/rewards.dart';

void main() {
  test('completed focus earns exactly one fifth in seconds', () {
    expect(RewardWallet.earnedSeconds(const Duration(minutes: 25)), 300);
    expect(RewardWallet.earnedSeconds(const Duration(minutes: 1)), 12);
    expect(RewardWallet.earnedSeconds(const Duration(minutes: 45)), 540);
  });
  test('balance accumulates and cannot be overdrawn', () {
    final wallet = RewardWallet();
    wallet.creditCompletedFocus(const Duration(minutes: 25));
    wallet.creditCompletedFocus(const Duration(minutes: 1));
    expect(wallet.seconds, 312);
    wallet.spend(60);
    expect(wallet.seconds, 252);
    expect(() => wallet.spend(253), throwsArgumentError);
    expect(() => wallet.spend(0), throwsArgumentError);
    expect(() => wallet.spend(-1), throwsArgumentError);
    expect(wallet.seconds, 252);
  });
}
