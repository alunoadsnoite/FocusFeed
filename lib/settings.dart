import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'focus_strings.dart';

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
  Future<String?> loadLanguage();
  Future<void> saveLanguage(String value);
}

class NativeSettingsPlatform implements SettingsPlatform {
  static const channel = MethodChannel('focusfeed/settings');

  @override
  Future<String?> loadTheme() => channel.invokeMethod<String>('loadTheme');

  @override
  Future<void> saveTheme(String value) =>
      channel.invokeMethod<void>('saveTheme', {'value': value});

  @override
  Future<String?> loadLanguage() =>
      channel.invokeMethod<String>('loadLanguage');

  @override
  Future<void> saveLanguage(String value) =>
      channel.invokeMethod<void>('saveLanguage', {'value': value});
}

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsPlatform? platform})
    : _platform = platform ?? NativeSettingsPlatform();

  final SettingsPlatform _platform;
  AppThemeMode _mode = AppThemeMode.system;
  AppLanguage _language = AppLanguage.portuguese;
  bool _disposed = false;
  bool _languageChosen = false;

  AppThemeMode get mode => _mode;
  AppLanguage get language => _language;

  Future<void> load() => Future.wait([_loadTheme(), _loadLanguage()]);

  Future<void> _loadTheme() async {
    try {
      final value = await _platform.loadTheme();
      if (_disposed || value == null) return;
      _mode = AppThemeMode.parse(value);
      notifyListeners();
    } catch (_) {
      // Sem canal nativo (testes ou plataforma sem suporte): mantém o padrão.
    }
  }

  Future<void> _loadLanguage() async {
    try {
      final value = await _platform.loadLanguage();
      if (_disposed || _languageChosen) return;
      _language = AppLanguage.parse(value);
      notifyListeners();
    } catch (_) {
      // Keep Brazilian Portuguese if the native preference cannot be read.
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _languageChosen = true;
    if (language != _language) {
      _language = language;
      notifyListeners();
    }
    try {
      await _platform.saveLanguage(language.tag);
    } catch (_) {
      // The selection is still valid for the current run.
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
    final strings = context.strings;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(strings.text('Idioma'), style: theme.textTheme.titleMedium),
          RadioGroup<AppLanguage>(
            groupValue: controller.language,
            onChanged: (value) {
              if (value != null) controller.setLanguage(value);
            },
            child: Column(
              children: [
                for (final language in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    value: language,
                    title: Text(language.label),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(strings.text('Aparência'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            strings.text(
              'Escolha o tema do aplicativo. O modo automático acompanha o sistema.',
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<AppThemeMode>(
            key: const Key('themeMode'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: AppThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(strings.text('Claro')),
              ),
              ButtonSegment(
                value: AppThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(strings.text('Escuro')),
              ),
              ButtonSegment(
                value: AppThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined),
                label: Text(strings.text('Auto')),
              ),
            ],
            selected: {controller.mode},
            onSelectionChanged: (selection) =>
                controller.setMode(selection.first),
          ),
          const SizedBox(height: 24),
          Text(
            strings.text('Desenvolvedor'),
            style: theme.textTheme.titleMedium,
          ),
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
                          SnackBar(
                            content: Text(strings.text('E-mail copiado.')),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(strings.text('Copiar e-mail')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(strings.text('Sobre'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                strings.text(
                  'FocusFeed é um Pomodoro offline com bloqueio de apps e recompensa proporcional. Não há conta, anúncios, analytics nem conexão de rede em tempo de execução. Todo o progresso fica no aparelho.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
