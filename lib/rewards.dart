/// Taxa de recompensa aplicada ao tempo concluído.
///
/// Padrão: 20% de cada foco concluído. O valor deve ser > 0 e <= 1.
/// Use [earnedSeconds] com [rate] para experimentar diferentes taxas
/// sem alterar o fluxo de crédito.
class RewardWallet {
  static const double defaultRate = 0.2;

  int _seconds = 0;
  int get seconds => _seconds;

  void restore(int seconds) {
    if (seconds < 0) throw ArgumentError.value(seconds, 'seconds');
    _seconds = seconds;
  }

  /// Tempo (em segundos) ganho por um foco concluído.
  static int earnedSeconds(Duration worked, {double? rate}) {
    if (worked.isNegative) throw ArgumentError.value(worked, 'worked');
    final r = rate ?? defaultRate;
    if (r <= 0 || r > 1) {
      throw ArgumentError.value(
        r,
        'rate',
        'A taxa de recompensa deve ser > 0 e <= 1.',
      );
    }
    return (worked.inSeconds * r).round();
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
