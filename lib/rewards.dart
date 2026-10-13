/// Stores exact whole seconds; 20% = one fifth of completed focus time.
class RewardWallet {
  int _seconds = 0;
  int get seconds => _seconds;

  void restore(int seconds) {
    if (seconds < 0) throw ArgumentError.value(seconds, 'seconds');
    _seconds = seconds;
  }

  static int earnedSeconds(Duration worked) {
    if (worked.isNegative) throw ArgumentError.value(worked, 'worked');
    return worked.inSeconds ~/ 5;
  }

  int creditCompletedFocus(Duration worked) {
    final earned = earnedSeconds(worked);
    _seconds += earned;
    return earned;
  }

  void spend(int seconds) {
    if (seconds <= 0 || seconds > _seconds) {
      throw ArgumentError.value(seconds, 'seconds', 'Saldo insuficiente');
    }
    _seconds -= seconds;
  }
}

String rewardLabel(int seconds) => seconds % 60 == 0
    ? '${seconds ~/ 60} min'
    : '${seconds ~/ 60} min ${seconds % 60} s';
