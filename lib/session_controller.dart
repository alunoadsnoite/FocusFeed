import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'local_progress_store.dart';

abstract class SessionPlatform {
  Future<dynamic> invoke(String method, [Map<String, dynamic>? arguments]);
}

class NativeSessionPlatform implements SessionPlatform {
  static const channel = MethodChannel('focusfeed/session');
  @override
  Future<dynamic> invoke(String method, [Map<String, dynamic>? arguments]) =>
      channel.invokeMethod<dynamic>(method, arguments);
}

class InstalledApp {
  InstalledApp(this.package, this.label, this.icon);
  final String package;
  final String label;
  final Uint8List? icon;
  factory InstalledApp.fromMap(Map raw) {
    Uint8List? icon;
    try {
      if ((raw['icon'] as String? ?? '').isNotEmpty) {
        icon = base64Decode(raw['icon'] as String);
      }
    } catch (_) {
      /* Use a fallback icon. */
    }
    return InstalledApp(raw['package'] as String, raw['label'] as String, icon);
  }
}

class SessionView {
  SessionView({
    required this.apps,
    required this.balance,
    required this.history,
    required this.phase,
    required this.focusTotal,
    required this.focusRemaining,
    required this.rewardRemaining,
    required this.monitorRunning,
    required this.permissionsReady,
    required this.notificationsEnabled,
    required this.platform,
    this.notice = '',
    this.selectionCount = 0,
  });
  final Map<String, bool> apps;
  final int balance;
  final Map<String, int> history;
  final String phase;
  final int focusTotal, focusRemaining, rewardRemaining, selectionCount;
  final bool monitorRunning, permissionsReady, notificationsEnabled;
  final String platform, notice;
  bool get active => const ['focus', 'reward', 'locked'].contains(phase);
  bool get blocking =>
      active && phase != 'reward' && monitorRunning && permissionsReady;
  factory SessionView.fromNative(Map raw) {
    final json = jsonDecode(raw['progress'] as String) as Map;
    if (json['version'] != 2) {
      throw const FormatException('Versão de progresso incompatível.');
    }
    final session = json['session'] as Map;
    final phase = session['phase'] as String;
    if (!const [
      'idle',
      'focus',
      'paused',
      'reward',
      'locked',
    ].contains(phase)) {
      throw const FormatException('Sessão inválida.');
    }
    final balance = (json['rewardSeconds'] as num).toInt();
    if (balance < 0) throw const FormatException('Saldo inválido.');
    return SessionView(
      apps: Map<String, bool>.from(json['apps'] as Map),
      balance: balance,
      history: (json['focusByDay'] as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
      phase: phase,
      focusTotal: (session['focusTotalSeconds'] as num).toInt(),
      focusRemaining: (session['focusRemainingSeconds'] as num).toInt(),
      rewardRemaining: (session['rewardRemainingSeconds'] as num).toInt(),
      monitorRunning: raw['monitorRunning'] == true,
      permissionsReady: raw['permissionsReady'] == true,
      notificationsEnabled: raw['notificationsEnabled'] == true,
      platform: raw['platform'] as String,
      notice: json['notice'] as String? ?? '',
      selectionCount: (raw['selectionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Presentation controller. Native storage/service is the sole session authority.
class SessionController extends ChangeNotifier {
  SessionController({
    SessionPlatform? platform,
    DateTime Function()? now,
    bool poll = true,
  }) : _platform = platform ?? NativeSessionPlatform(),
       _now = now ?? DateTime.now {
    if (poll) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(refresh()),
      );
    }
  }
  final SessionPlatform _platform;
  final DateTime Function() _now;
  Timer? _ticker;
  SessionView? state;
  List<InstalledApp> apps = [];
  String? error;
  bool busy = false;
  bool _refreshing = false;
  bool _disposed = false;
  int _revision = 0;
  bool get loaded => state != null;
  int get focusToday => state?.history[localDayKey(_now())] ?? 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _failure(Object failure) {
    error = failure is PlatformException
        ? failure.message ?? 'Falha na operação nativa.'
        : 'Não foi possível carregar a sessão. Tente novamente.';
  }

  Future<void> initialize() async {
    if (busy || _disposed) return;
    busy = true;
    _notify();
    try {
      final raw = await _platform.invoke('initialize');
      final catalog = await _platform.invoke('apps');
      if (_disposed) return;
      state = SessionView.fromNative(raw as Map);
      apps = (catalog as List)
          .map((item) => InstalledApp.fromMap(item as Map))
          .toList();
      error = null;
    } catch (e) {
      _failure(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    if (!loaded || busy || _refreshing || _disposed) return;
    _refreshing = true;
    final revision = _revision;
    try {
      final raw = await _platform.invoke('status');
      if (_disposed || revision != _revision) return;
      state = SessionView.fromNative(raw as Map);
      error = null;
      _notify();
    } catch (e) {
      if (revision == _revision) {
        _failure(e);
        _notify();
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _command(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    if (!loaded || busy || _disposed) return;
    _revision++;
    busy = true;
    _notify();
    try {
      final raw = await _platform.invoke(method, arguments);
      if (_disposed) return;
      state = SessionView.fromNative(raw as Map);
      error = null;
    } catch (e) {
      _failure(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> start() =>
      _command('start', {'seconds': state?.focusTotal ?? 1500});
  Future<void> pause() => _command('pause');
  Future<void> stop() => _command('stop');
  Future<void> duration(int seconds) =>
      _command('duration', {'seconds': seconds});
  Future<void> select(String package, bool selected) =>
      _command('select', {'package': package, 'selected': selected});
  Future<void> pickApps() => _command('pickApps');
  Future<void> reward(int seconds) async {
    if (seconds <= 0 || seconds > (state?.balance ?? 0)) {
      error = 'Saldo insuficiente. Conclua uma sessão de foco para ganhar recompensa.';
      _notify();
      return;
    }
    await _command('reward', {'seconds': seconds});
  }

  Future<void> notifications() async {
    if (busy || _disposed) return;
    try {
      await _platform.invoke('requestNotifications');
      await refresh();
    } catch (e) {
      _failure(e);
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _ticker?.cancel();
    // Leaving the UI must not stop a persisted native session.
    super.dispose();
  }
}
