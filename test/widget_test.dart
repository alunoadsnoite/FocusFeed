import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_feed/main.dart';
import 'package:focus_feed/permissions.dart';
import 'package:focus_feed/session_controller.dart';
import 'package:focus_feed/settings.dart';

import 'fake_session_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          FocusPermissions.channel,
          (_) async => {'supported': true, 'usage': true, 'overlay': true},
        );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(FocusPermissions.channel, null),
  );
  testWidgets('zero reward disables release while installed apps are shown', (
    tester,
  ) async {
    final native = FakeSessionPlatform();
    final c = SessionController(platform: native, poll: false);
    await tester.pumpWidget(FocusFeedApp(controller: c));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Liberar Redes por 0 min'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Liberar Redes por 0 min'),
    );
    expect(button.onPressed, isNull);
    await tester.scrollUntilVisible(
      find.text('Outro app'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.widgetWithText(CheckboxListTile, 'Outro app'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Outro app'));
    await tester.pumpAndSettle();
    expect(native.calls.last, 'select');
    expect(native.arguments.last, {
      'package': 'com.example.other',
      'selected': true,
    });
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'reopening displays restored paused timer and persisted fractions',
    (tester) async {
      final native = FakeSessionPlatform();
      native.progress['rewardSeconds'] = 312;
      native.progress['session']['phase'] = 'paused';
      native.progress['session']['focusRemainingSeconds'] = 900;
      native.progress['notice'] = 'Celular reiniciado.';
      final c = SessionController(platform: native, poll: false);
      await tester.pumpWidget(FocusFeedApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('Retomar Foco'), findsOneWidget);
      expect(find.text('Celular reiniciado.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Saldo: 5 min 12 s'), 200);
      expect(find.text('Saldo: 5 min 12 s'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets('native reward expiry and failure to protect are visible', (
    tester,
  ) async {
    final native = FakeSessionPlatform();
    native.progress['session']['phase'] = 'reward';
    native.progress['session']['rewardRemainingSeconds'] = 12;
    final c = SessionController(platform: native, poll: false);
    await tester.pumpWidget(FocusFeedApp(controller: c));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Recompensa: 00:12'), 200);
    expect(find.text('Recompensa: 00:12'), findsOneWidget);
    native.progress['session']['phase'] = 'locked';
    native.monitor = false;
    await c.refresh();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('sessionStatus')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Bloqueio indisponível — verifique permissões e serviço'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('failed initial read does not expose default balances/actions', (
    tester,
  ) async {
    final native = FakeSessionPlatform()..fail = 'initialize';
    final c = SessionController(platform: native, poll: false);
    await tester.pumpWidget(FocusFeedApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Tentar carregar novamente'), findsOneWidget);
    expect(find.text('Iniciar Foco'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('settings tab selects a theme and shows developer contact', (
    tester,
  ) async {
    final native = FakeSessionPlatform();
    final settings = SettingsController(platform: _FakeSettingsPlatform());
    final c = SessionController(platform: native, poll: false);
    await tester.pumpWidget(FocusFeedApp(controller: c, settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Valdenor Tavares'), findsOneWidget);
    expect(find.text('valdenor.sa@proton.me'), findsOneWidget);
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    expect(settings.mode, AppThemeMode.dark);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
    c.dispose();
  });
  testWidgets('language switches without losing a paused session', (
    tester,
  ) async {
    final native = FakeSessionPlatform();
    native.progress['session']['phase'] = 'paused';
    native.progress['session']['focusRemainingSeconds'] = 900;
    native.progress['notice'] =
        'Foco concluído. Recompensa adicionada ao saldo.';
    final platform = _FakeSettingsPlatform();
    final settings = SettingsController(platform: platform);
    final controller = SessionController(platform: native, poll: false);
    await tester.pumpWidget(
      FocusFeedApp(controller: controller, settings: settings),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(platform.storedLanguage, 'en-US');
    expect(find.text('Language'), findsOneWidget);
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(platform.storedLanguage, 'es-ES');
    await tester.tap(find.text('Enfoque'));
    await tester.pumpAndSettle();
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('Reanudar enfoque'), findsOneWidget);
    expect(
      find.text('Enfoque completado. La recompensa se añadió al saldo.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
    controller.dispose();
  });

  testWidgets('iOS exposes the native Screen Time picker', (tester) async {
    final native = FakeSessionPlatform()..platform = 'ios';
    final c = SessionController(platform: native, poll: false);
    await tester.pumpWidget(FocusFeedApp(controller: c));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Selecionar apps no iOS'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Selecionar apps no iOS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selecionar apps no iOS'));
    await tester.pumpAndSettle();
    expect(native.calls.last, 'pickApps');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}

class _FakeSettingsPlatform implements SettingsPlatform {
  String? storedLanguage;

  @override
  Future<String?> loadLanguage() async => storedLanguage;

  @override
  Future<void> saveLanguage(String value) async => storedLanguage = value;

  String? stored;

  @override
  Future<String?> loadTheme() async => stored;

  @override
  Future<void> saveTheme(String value) async => stored = value;
}
