import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_feed/settings.dart';

class FakeSettingsPlatform implements SettingsPlatform {
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

  test('theme mode maps to the Flutter ThemeMode', () {
    expect(AppThemeMode.system.themeMode, ThemeMode.system);
    expect(AppThemeMode.light.themeMode, ThemeMode.light);
    expect(AppThemeMode.dark.themeMode, ThemeMode.dark);
  });
}
