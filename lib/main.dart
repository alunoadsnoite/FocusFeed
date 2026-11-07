import 'dart:async';

import 'package:flutter/material.dart';

import 'history_view.dart';
import 'permissions.dart';
import 'rewards.dart';
import 'session_controller.dart';
import 'settings.dart';

void main() => runApp(const FocusFeedApp());

class FocusFeedApp extends StatefulWidget {
  const FocusFeedApp({super.key, this.now, this.controller, this.settings});

  final DateTime Function()? now;
  final SessionController? controller;
  final SettingsController? settings;

  @override
  State<FocusFeedApp> createState() => _FocusFeedAppState();
}

class _FocusFeedAppState extends State<FocusFeedApp> {
  late final SettingsController _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? SettingsController();
    unawaited(_settings.load());
  }

  @override
  void dispose() {
    if (widget.settings == null) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _settings,
    builder: (context, _) => MaterialApp(
      title: 'FocusFeed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: _settings.mode.themeMode,
      home: FocusScreen(
        now: widget.now,
        controller: widget.controller,
        settings: _settings,
      ),
    ),
  );
}

class FocusScreen extends StatefulWidget {
  const FocusScreen({
    super.key,
    this.now,
    this.controller,
    required this.settings,
  });

  final DateTime Function()? now;
  final SessionController? controller;
  final SettingsController settings;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  late final SessionController _controller;
  int? _rewardChoice;
  String _search = '';
  int _index = 0;
  final _searchController = TextEditingController();

  static const _titles = ['FocusFeed', 'Histórico', 'Ajustes'];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SessionController(now: widget.now);
    _controller.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_controller.initialize());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    _controller.setForeground(resumed);
    if (resumed) unawaited(_controller.refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_changed);
    _searchController.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  String _time(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  Future<void> _stop() async {
    final phase = _controller.state?.phase;
    if (phase == null || phase == 'idle') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parar a sessão?'),
        content: const Text(
          'O tempo restante será descartado. Uma recompensa já usada não é '
          'devolvida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Parar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final s = c.state;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('FocusFeed')),
        body: Center(
          child: c.error == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(c.error!),
                    ),
                    TextButton(
                      onPressed: c.busy ? null : c.initialize,
                      child: const Text('Tentar carregar novamente'),
                    ),
                  ],
                ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: SafeArea(
        child: switch (_index) {
          0 => _focusTab(context, c, s),
          1 => HistoryView(state: s, now: c.now),
          _ => SettingsView(controller: widget.settings),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Foco',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  Widget _focusTab(
    BuildContext context,
    SessionController c,
    SessionView s,
  ) {
    final cap = s.balance > 86400 ? 86400 : s.balance;
    final amounts = <int>{
      if (cap >= 60) 60,
      if (cap >= 300) 300,
      if (cap >= 600) 600,
      if (cap >= 900) 900,
      if (cap >= 1800) 1800,
      if (cap > 0) cap,
    }.toList()..sort();
    final chosen = amounts.contains(_rewardChoice)
        ? _rewardChoice!
        : amounts.isEmpty
        ? 0
        : amounts.last;
    final idle = s.phase == 'idle';
    final catalog = c.apps
        .where((app) => app.label.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final status = switch (s.phase) {
      'reward' => 'Recompensa ativa — redes liberadas',
      'paused' => 'Foco pausado — bloqueio desativado',
      'focus' || 'locked' =>
        s.blocking
            ? 'Bloqueio ativo'
            : 'Bloqueio indisponível — verifique permissões e serviço',
      _ => 'Pronto para focar',
    };
    final progress = (1 - s.focusRemaining / s.focusTotal).clamp(0.0, 1.0);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Uma sessão de cada vez.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Foco concluído hoje: ${rewardLabel(c.focusToday)}'),
            Text(
              'Recompensa ao concluir: '
              '${rewardLabel(RewardWallet.earnedSeconds(Duration(seconds: s.focusTotal)))}',
            ),
            Text(status, key: const Key('sessionStatus')),
            if (s.notice.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(s.notice),
              ),
            if (c.error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        c.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      TextButton(
                        onPressed: c.busy ? null : c.refresh,
                        child: const Text('Verificar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            if (c.busy) const LinearProgressIndicator(),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              key: ValueKey(s.focusTotal),
              initialValue: s.focusTotal,
              decoration: const InputDecoration(
                labelText: 'Duração do foco',
                border: OutlineInputBorder(),
              ),
              items: [60, 300, 900, 1500, 2700, 3600]
                  .map(
                    (seconds) => DropdownMenuItem(
                      value: seconds,
                      child: Text('${seconds ~/ 60} minutos'),
                    ),
                  )
                  .toList(),
              onChanged: idle && !c.busy
                  ? (value) {
                      if (value != null) unawaited(c.duration(value));
                    }
                  : null,
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'Tempo restante de foco',
              value: _time(s.focusRemaining),
              child: Text(
                _time(s.focusRemaining),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Progresso do foco',
              value: '${(progress * 100).round()}%',
              child: LinearProgressIndicator(value: progress),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed:
                      !c.busy && !['focus', 'reward'].contains(s.phase)
                      ? c.start
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    s.phase == 'paused' ||
                            (s.phase == 'locked' && s.focusRemaining > 0)
                        ? 'Retomar Foco'
                        : 'Iniciar Foco',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: !c.busy && s.phase == 'focus' ? c.pause : null,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausar'),
                ),
                OutlinedButton.icon(
                  onPressed: !c.busy && !idle ? _stop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Parar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo: ${rewardLabel(s.balance)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text('Ganhe 20% do tempo de cada foco concluído.'),
                    const SizedBox(height: 4),
                    const Text(
                      'Liberar redes pausa um foco ativo. Sem foco ativo, os '
                      'apps escolhidos ficam bloqueados até Parar.',
                      style: TextStyle(fontSize: 12),
                    ),
                    if (s.phase == 'reward')
                      Text(
                        'Recompensa: ${_time(s.rewardRemaining)}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      )
                    else ...[
                      if (s.balance == 0)
                        const Text(
                          'Sem saldo. Conclua um foco para liberar as redes.',
                        ),
                      if (amounts.isNotEmpty)
                        DropdownButton<int>(
                          key: const Key('rewardAmount'),
                          value: chosen,
                          items: amounts
                              .map(
                                (seconds) => DropdownMenuItem(
                                  value: seconds,
                                  child: Text(rewardLabel(seconds)),
                                ),
                              )
                              .toList(),
                          onChanged: c.busy
                              ? null
                              : (value) =>
                                    setState(() => _rewardChoice = value),
                        ),
                      FilledButton(
                        onPressed: chosen > 0 && !c.busy
                            ? () => c.reward(chosen)
                            : null,
                        child: Text(
                          'Liberar Redes por ${rewardLabel(chosen)}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(
                  s.notificationsEnabled
                      ? 'Notificações ativadas'
                      : 'Notificações desativadas',
                ),
                subtitle: const Text(
                  'Receba avisos ao terminar o foco e a pausa.',
                ),
                trailing: TextButton(
                  onPressed: c.busy ? null : c.notifications,
                  child: const Text('Configurar'),
                ),
              ),
            ),
            const PermissionsPanel(),
            const SizedBox(height: 24),
            Text(
              'Apps selecionados para bloqueio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (s.platform == 'ios') ...[
              Text('${s.selectionCount} itens selecionados pelo Screen Time'),
              OutlinedButton(
                onPressed: idle && !c.busy ? c.pickApps : null,
                child: const Text('Selecionar apps no iOS'),
              ),
            ] else ...[
              TextField(
                key: const Key('appSearch'),
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar apps instalados',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
              if (catalog.isEmpty)
                const Text(
                  'Nenhum app encontrado. Atualize após instalar um app.',
                ),
              ...catalog.map(
                (app) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: app.icon != null
                      ? Image.memory(app.icon!, width: 36, height: 36)
                      : const Icon(Icons.apps),
                  title: Text(app.label),
                  value: s.apps[app.package] ?? false,
                  onChanged: idle && !c.busy
                      ? (value) => c.select(app.package, value ?? false)
                      : null,
                ),
              ),
              TextButton(
                onPressed: idle && !c.busy ? c.initialize : null,
                child: const Text('Atualizar apps instalados'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
