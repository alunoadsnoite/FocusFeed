import 'package:flutter/material.dart';

import 'day_key.dart';
import 'focus_strings.dart';
import 'rewards.dart';
import 'session_controller.dart';

/// Histórico local de foco já persistido pelo motor nativo.
class HistoryView extends StatelessWidget {
  const HistoryView({super.key, required this.state, required this.now});

  final SessionView state;
  final DateTime now;

  static const _days = 14;

  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

  int _streak(Map<String, int> history, DateTime today) {
    var cursor = today;
    if ((history[localDayKey(cursor)] ?? 0) == 0) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var count = 0;
    while ((history[localDayKey(cursor)] ?? 0) > 0) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.strings;
    final material = MaterialLocalizations.of(context);
    String short(DateTime date) => material.formatShortMonthDay(date);
    final today = _day(now);
    final days = List.generate(
      _days,
      (index) =>
          DateTime(today.year, today.month, today.day - (_days - 1 - index)),
    );
    final values = days
        .map((day) => state.history[localDayKey(day)] ?? 0)
        .toList();
    final maxValue = values.fold<int>(0, (a, b) => a > b ? a : b);
    final periodTotal = values.fold<int>(0, (a, b) => a + b);
    final allTimeTotal = state.history.values.fold<int>(0, (a, b) => a + b);
    final todayTotal = state.history[localDayKey(today)] ?? 0;
    final streak = _streak(state.history, today);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          strings.text('Seu progresso'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Stat(label: strings.text('Hoje'), value: rewardLabel(todayTotal)),
            _Stat(
              label: strings.text('Últimos {0} dias', [_days]),
              value: rewardLabel(periodTotal),
            ),
            _Stat(
              label: strings.text('Sequência'),
              value: strings.text(streak == 1 ? '{0} dia' : '{0} dias', [
                streak,
              ]),
            ),
            _Stat(
              label: strings.text('Total'),
              value: rewardLabel(allTimeTotal),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          strings.text('Últimos {0} dias', [_days]),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (maxValue == 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                strings.text(
                  'Ainda não há focos concluídos. Termine uma sessão para começar seu histórico.',
                ),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var index = 0; index < days.length; index++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Tooltip(
                                message:
                                    '${short(days[index])}: ${rewardLabel(values[index])}',
                                child: Container(
                                  height: maxValue == 0
                                      ? 2
                                      : 4 + (values[index] / maxValue) * 116,
                                  decoration: BoxDecoration(
                                    color: values[index] == 0
                                        ? theme
                                              .colorScheme
                                              .surfaceContainerHighest
                                        : theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        short(days.first),
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(short(days.last), style: theme.textTheme.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(strings.text('Detalhes'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...days.reversed.map(
          (day) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available_outlined),
            title: Text(short(day)),
            trailing: Text(
              (state.history[localDayKey(day)] ?? 0) == 0
                  ? strings.text('Sem foco')
                  : rewardLabel(state.history[localDayKey(day)]!),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
