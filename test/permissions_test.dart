import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_feed/permissions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = FocusPermissions.channel;
  var grants = <String, dynamic>{};
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => grants);
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test('Android requires usage and overlay only', () async {
    grants = {'supported': true, 'usage': true, 'overlay': false};
    expect(await FocusPermissions.hasRequiredPermissions(), isFalse);
    grants['overlay'] = true;
    expect(await FocusPermissions.hasRequiredPermissions(), isTrue);
    grants['usage'] = false;
    expect(await FocusPermissions.hasRequiredPermissions(), isFalse);
  });
  test('iOS requires Screen Time authorization', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    grants = {'supported': true, 'screenTime': false};
    expect(await FocusPermissions.hasRequiredPermissions(), isFalse);
    grants['screenTime'] = true;
    expect(await FocusPermissions.hasRequiredPermissions(), isTrue);
    grants['supported'] = false;
    expect(await FocusPermissions.hasRequiredPermissions(), isFalse);
  });
  test('native failures return false', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'failed'),
        );
    expect(await FocusPermissions.hasRequiredPermissions(), isFalse);
  });
}
