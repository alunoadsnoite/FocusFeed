import 'dart:convert';

String localDayKey(DateTime date) {
  final local = date.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

class ProgressData {
  static const defaultApps = {
    'Instagram': true,
    'TikTok': true,
    'YouTube': true,
  };
  ProgressData({
    Map<String, bool>? apps,
    this.rewardSeconds = 0,
    Map<String, int>? focusByDay,
  }) : apps = Map.unmodifiable(apps ?? defaultApps),
       focusByDay = Map.unmodifiable(focusByDay ?? {}) {
    if (rewardSeconds < 0 || this.focusByDay.values.any((v) => v < 0)) {
      throw ArgumentError('Valores de progresso não podem ser negativos.');
    }
  }
  final Map<String, bool> apps;
  final int rewardSeconds;
  final Map<String, int> focusByDay;
  int focusToday(DateTime now) => focusByDay[localDayKey(now)] ?? 0;

  String encode() => jsonEncode({
    'version': 1,
    'apps': apps,
    'rewardSeconds': rewardSeconds,
    'focusByDay': focusByDay,
  });

  factory ProgressData.decode(String encoded) {
    final raw = jsonDecode(encoded);
    if (raw is! Map ||
        raw['version'] != 1 ||
        raw['apps'] is! Map ||
        raw['rewardSeconds'] is! int ||
        raw['rewardSeconds'] < 0 ||
        raw['focusByDay'] is! Map) {
      throw const FormatException(
        'Formato de progresso inválido ou incompatível.',
      );
    }
    final apps = Map<String, bool>.from(defaultApps);
    for (final entry in (raw['apps'] as Map).entries) {
      if (entry.key is! String || entry.value is! bool) {
        throw const FormatException('Seleção inválida.');
      }
      if (apps.containsKey(entry.key)) {
        apps[entry.key as String] = entry.value as bool;
      }
    }
    final history = <String, int>{};
    for (final entry in (raw['focusByDay'] as Map).entries) {
      final key = entry.key;
      if (key is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key) ||
          entry.value is! int ||
          entry.value < 0) {
        throw const FormatException('Histórico inválido.');
      }
      final parsed = DateTime.tryParse(key);
      if (parsed == null || localDayKey(parsed) != key) {
        throw const FormatException('Data inválida.');
      }
      history[key] = entry.value as int;
    }
    return ProgressData(
      apps: apps,
      rewardSeconds: raw['rewardSeconds'] as int,
      focusByDay: history,
    );
  }
}
