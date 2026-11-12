import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_feed/settings.dart';
import 'package:focus_feed/focus_strings.dart';

class FakeSettingsPlatform implements SettingsPlatform {
  String? storedLanguage;

  @override
  Future<String?> loadLanguage() async => storedLanguage;

  @override
  Future<void> saveLanguage(String value) async => storedLanguage = value;

  String? stored;
  int saves = 0;

  @override
  Future<String?> loadTheme() async => stored;

  @override
  Future<void> saveTheme(String value) async {
    stored = value;
    saves++;
  }
}

void main() {
  test('restores and persists the selected theme', () async {
    final platform = FakeSettingsPlatform()..stored = 'dark';
    final controller = SettingsController(platform: platform);
    await controller.load();
    expect(controller.mode, AppThemeMode.dark);

    await controller.setMode(AppThemeMode.light);
    expect(controller.mode, AppThemeMode.light);
    expect(platform.stored, 'light');
    expect(platform.saves, 1);
    controller.dispose();
  });

  test('unknown or missing values fall back to system', () async {
    final platform = FakeSettingsPlatform()..stored = 'purple';
    final controller = SettingsController(platform: platform);
    await controller.load();
    expect(controller.mode, AppThemeMode.system);
    controller.dispose();
  });

  test('language restores and persists separately from theme', () async {
    final platform = FakeSettingsPlatform()
      ..stored = 'dark'
      ..storedLanguage = 'es-ES';
    final controller = SettingsController(platform: platform);
    await controller.load();
    expect(controller.language, AppLanguage.spanish);
    expect(controller.mode, AppThemeMode.dark);

    await controller.setLanguage(AppLanguage.english);
    expect(platform.storedLanguage, 'en-US');
    expect(platform.stored, 'dark');
    controller.dispose();
  });

  test('invalid and missing languages default to Brazilian Portuguese', () {
    expect(AppLanguage.parse(null), AppLanguage.portuguese);
    expect(AppLanguage.parse('unknown'), AppLanguage.portuguese);
  });

  test('theme mode maps to the Flutter ThemeMode', () {
    expect(AppThemeMode.system.themeMode, ThemeMode.system);
    expect(AppThemeMode.light.themeMode, ThemeMode.light);
    expect(AppThemeMode.dark.themeMode, ThemeMode.dark);
  });
}
