import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Preferência de tema persistida no armazenamento nativo.
enum AppThemeMode {
  system('Automático', ThemeMode.system),
  light('Claro', ThemeMode.light),
  dark('Escuro', ThemeMode.dark);

  const AppThemeMode(this.label, this.themeMode);

  final String label;
  final ThemeMode themeMode;

  static AppThemeMode parse(String? value) => values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => AppThemeMode.system,
  );
}

abstract class SettingsPlatform {
  Future<String?> loadTheme();
  Future<void> saveTheme(String value);
}

class NativeSettingsPlatform implements SettingsPlatform {
  static const channel = MethodChannel('focusfeed/settings');

  @override
  Future<String?> loadTheme() => channel.invokeMethod<String>('loadTheme');

  @override
  Future<void> saveTheme(String value) =>
      channel.invokeMethod<void>('saveTheme', {'value': value});
}

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsPlatform? platform})
    : _platform = platform ?? NativeSettingsPlatform();

  final SettingsPlatform _platform;
  AppThemeMode _mode = AppThemeMode.system;
  bool _disposed = false;

  AppThemeMode get mode => _mode;

  Future<void> load() async {
    try {
      final value = await _platform.loadTheme();
      if (_disposed || value == null) return;
      _mode = AppThemeMode.parse(value);
      notifyListeners();
    } catch (_) {
      // Sem canal nativo (testes ou plataforma sem suporte): mantém o padrão.
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _platform.saveTheme(mode.name);
    } catch (_) {
      // A preferência continua válida nesta execução mesmo sem persistência.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Aparência', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Escolha o tema do aplicativo. O modo automático acompanha o sistema.',
          ),
          const SizedBox(height: 12),
          SegmentedButton<AppThemeMode>(
            key: const Key('themeMode'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: AppThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: AppThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Escuro'),
              ),
              ButtonSegment(
                value: AppThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('Auto'),
              ),
            ],
            selected: {controller.mode},
            onSelectionChanged: (selection) =>
                controller.setMode(selection.first),
          ),
          const SizedBox(height: 24),
          Text('Desenvolvedor', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valdenor Tavares', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const SelectableText('valdenor.sa@proton.me'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: 'valdenor.sa@proton.me'),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('E-mail copiado.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar e-mail'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Sobre', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'FocusFeed é um Pomodoro offline com bloqueio de apps e '
                'recompensa proporcional. Não há conta, anúncios, analytics '
                'nem conexão de rede em tempo de execução. Todo o progresso '
                'fica no aparelho.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
