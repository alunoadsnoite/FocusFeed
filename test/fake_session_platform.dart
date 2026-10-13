import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:focus_feed/session_controller.dart';

class FakeSessionPlatform implements SessionPlatform {
  final calls = <String>[];
  final arguments = <Map<String, dynamic>?>[];
  String? fail;
  Completer<dynamic>? delayedStatus;
  Map<String, dynamic> progress = {
    'version': 2,
    'apps': {'com.instagram.android': true},
    'rewardSeconds': 0,
    'focusByDay': <String, int>{},
    'notice': '',
    'session': {
      'id': '',
      'phase': 'idle',
      'focusTotalSeconds': 1500,
      'focusRemainingSeconds': 1500,
      'rewardRemainingSeconds': 0,
    },
  };
  bool monitor = false;
  bool permissions = true;
  bool notifications = false;
  String platform = 'android';
  Map<String, dynamic> get response => {
    'progress': jsonEncode(progress),
    'monitorRunning': monitor,
    'permissionsReady': permissions,
    'notificationsEnabled': notifications,
    'platform': platform,
    'selectionCount': 2,
  };
  @override
  Future<dynamic> invoke(String method, [Map<String, dynamic>? args]) async {
    calls.add(method);
    arguments.add(args);
    if (method == fail) {
      throw PlatformException(code: 'failed', message: 'Falha de teste.');
    }
    if (method == 'apps') {
      return platform == 'ios'
          ? []
          : [
              {
                'package': 'com.instagram.android',
                'label': 'Instagram',
                'icon': '',
              },
              {
                'package': 'com.example.other',
                'label': 'Outro app',
                'icon': '',
              },
            ];
    }
    if (method == 'requestNotifications') {
      notifications = true;
      return true;
    }
    if (method == 'status' && delayedStatus != null) {
      return delayedStatus!.future;
    }
    return response;
  }
}
