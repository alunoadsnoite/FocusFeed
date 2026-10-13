import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionStatus {
  const PermissionStatus({required this.supported, required this.grants});
  final bool supported;
  final Map<String, bool> grants;
  bool get ready =>
      supported && grants.isNotEmpty && grants.values.every((v) => v);
}

class FocusPermissions {
  static const channel = MethodChannel('focusfeed/permissions');
  static Future<PermissionStatus> check() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const PermissionStatus(supported: false, grants: {});
    }
    final raw = await channel.invokeMapMethod<String, dynamic>('check');
    final keys = defaultTargetPlatform == TargetPlatform.android
        ? ['usage', 'overlay']
        : ['screenTime'];
    return PermissionStatus(
      supported: raw?['supported'] == true,
      grants: {for (final key in keys) key: raw?[key] == true},
    );
  }

  /// True only when every permission required by this platform is granted.
  static Future<bool> hasRequiredPermissions() async {
    try {
      return (await check()).ready;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> request(String permission) =>
      channel.invokeMethod<void>('request', {'permission': permission});
}

class PermissionsPanel extends StatefulWidget {
  const PermissionsPanel({super.key});
  @override
  State<PermissionsPanel> createState() => _PermissionsPanelState();
}

class _PermissionsPanelState extends State<PermissionsPanel>
    with WidgetsBindingObserver {
  PermissionStatus? _status;
  String? _error;
  bool _busy = false;
  static const _labels = {
    'usage': 'Acesso ao uso dos apps',
    'overlay': 'Sobrepor outros apps',
    'screenTime': 'Autorizar Screen Time',
  };
  static const _explanations = {
    'usage': 'Permite consultar quais apps foram usados. Selecione FocusFeed e autorize o acesso.',
    'accessibility': 'Permite identificar mudanças de app. Selecione FocusFeed e ative o serviço. Não lê o conteúdo das telas.',
    'overlay': 'Permite exibir a futura tela de bloqueio sobre outros apps. Autorize FocusFeed nas configurações.',
    'screenTime': 'Autoriza o uso do Screen Time para a futura seleção, monitoração e restrição de apps.',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final status = await FocusPermissions.check();
      if (mounted) {
        setState(() {
          _status = status;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = null;
          _error = 'Não foi possível verificar as permissões. Tente novamente.';
        });
      }
    }
  }

  Future<void> _request(String key) async {
    setState(() => _busy = true);
    try {
      await FocusPermissions.request(key);
      await _refresh();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _error =
              error.message ?? 'Não foi possível solicitar a permissão.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível abrir a solicitação.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _status?.ready == true
                ? 'Permissões concedidas'
                : 'Permissões para bloqueio',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(
            'Autorize o monitoramento e bloqueio dos apps escolhidos. Notificações são opcionais.',
          ),
          if (_status != null && !_status!.supported)
            const Text('Disponível em Android e iOS 16 ou superior.'),
          if (_status == null && _error == null)
            const LinearProgressIndicator(),
          if (_status?.supported == true)
            for (final entry in _status!.grants.entries)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_labels[entry.key]}: ${entry.value ? "ativado" : "pendente"}',
                    ),
                    if (!entry.value) ...[
                      Text(_explanations[entry.key]!),
                      OutlinedButton(
                        onPressed: _busy ? null : () => _request(entry.key),
                        child: Text(
                          entry.key == 'screenTime'
                              ? 'Autorizar Screen Time'
                              : 'Abrir Configurações',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          TextButton(
            onPressed: _busy ? null : _refresh,
            child: const Text('Verificar permissões'),
          ),
        ],
      ),
    ),
  );
}
