import 'dart:async';

import 'package:flutter/material.dart';

import 'permissions.dart';
import 'rewards.dart';
import 'session_controller.dart';

void main() => runApp(const FocusFeedApp());

class FocusFeedApp extends StatelessWidget {
  const FocusFeedApp({super.key, this.now, this.controller});
  final DateTime Function()? now;
  final SessionController? controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FocusFeed',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: FocusScreen(now: now, controller: controller),
  );
}

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key, this.now, this.controller});
  final DateTime Function()? now;
  final SessionController? controller;
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  late final SessionController _controller;
  int? _rewardChoice;
  String _search = '';
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
    if (state == AppLifecycleState.resumed) unawaited(_controller.refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_changed);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  String _time(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
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
    final amounts = <int>{
      if (s.balance >= 60) 60,
      if (s.balance >= 300) 300,
      if (s.balance > 0) s.balance > 86400 ? 86400 : s.balance,
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
    return Scaffold(
      appBar: AppBar(title: const Text('FocusFeed')),
      body: SafeArea(
        child: Center(
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
                  child: Text(
                    _time(s.focusRemaining),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (1 - s.focusRemaining / s.focusTotal).clamp(0.0, 1.0),
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
                      onPressed: !c.busy && !idle ? c.stop : null,
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
                        const Text(
                          'Ganhe 20% do tempo de cada foco concluído.',
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
                  Text(
                    '${s.selectionCount} itens selecionados pelo Screen Time',
                  ),
                  OutlinedButton(
                    onPressed: idle && !c.busy ? c.pickApps : null,
                    child: const Text('Selecionar apps no iOS'),
                  ),
                ] else ...[
                  TextField(
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
        ),
      ),
    );
  }
}
