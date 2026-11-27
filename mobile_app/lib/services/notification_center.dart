import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/notification_banner.dart';
import 'api_client.dart';

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String message;
  final String sound;
  final String imageUrl;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.sound,
    this.imageUrl = '',
    this.isRead = false,
    this.createdAt = '',
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as num?)?.toInt() ?? 0,
        type: (j['type'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        sound: (j['sound'] ?? 'bell').toString(),
        imageUrl: (j['image_url'] ?? '').toString(),
        isRead: j['is_read'] == true,
        createdAt: (j['created_at'] ?? '').toString(),
      );

  /// Built from an FCM data payload (app in foreground).
  factory AppNotification.fromPush(Map<String, dynamic> d) => AppNotification(
        id: int.tryParse((d['notification_id'] ?? '').toString()) ?? 0,
        type: (d['type'] ?? 'info').toString(),
        title: (d['title'] ?? '').toString(),
        message: (d['message'] ?? '').toString(),
        sound: (d['sound'] ?? 'bell').toString(),
      );
}

/// Keeps the unread counter fresh and, while the app is open, shows an eye-catching
/// banner with sound for every new notification (admin messages and automatic ones).
/// Phone pushes (app closed/background) are handled by the system via Firebase.
class NotificationCenter with WidgetsBindingObserver {
  NotificationCenter._();
  static final NotificationCenter instance = NotificationCenter._();

  static const _pollInterval = Duration(seconds: 20);

  final ValueNotifier<int> unread = ValueNotifier<int>(0);
  bool synced = false;

  GlobalKey<NavigatorState>? navigatorKey;
  VoidCallback? openInbox;

  final AudioPlayer _player = AudioPlayer();
  final Set<int> _shown = <int>{};
  Timer? _timer;
  bool _started = false;
  bool _busy = false;
  int _lastId = 0;

  void setUnread(int value) {
    synced = true;
    if (unread.value != value) unread.value = value;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await _sync(silent: true);
    _restartTimer();
  }

  void stop() {
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    _lastId = 0;
    _shown.clear();
    synced = false;
    unread.value = 0;
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _sync(silent: false));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    if (state == AppLifecycleState.resumed) {
      // Anything that arrived while the app was in the background was already shown by the
      // system notification tray, so refresh quietly (no banner) and resume polling.
      _sync(silent: true);
      _restartTimer();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  Future<void> _sync({required bool silent}) async {
    if (_busy || !ApiClient.instance.isLoggedIn) return;
    _busy = true;
    try {
      final res = await ApiClient.instance.get(
        _lastId > 0 ? 'notifications?since_id=$_lastId' : 'notifications',
      );
      final latest = (res['latest_id'] as num?)?.toInt() ?? _lastId;
      final items = ((res['notifications'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();

      if (!silent && _lastId > 0) {
        final fresh = items.where((n) => !n.isRead && !_shown.contains(n.id)).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        for (final n in fresh) {
          _shown.add(n.id);
        }
        if (fresh.isNotEmpty) {
          final newest = fresh.last;
          present(
            fresh.length > 1
                ? AppNotification(
                    id: newest.id,
                    type: newest.type,
                    title: newest.title,
                    message: '${newest.message}\n+${fresh.length - 1} more notification(s)',
                    sound: newest.sound,
                    imageUrl: newest.imageUrl,
                  )
                : newest,
          );
        }
      } else {
        for (final n in items) {
          _shown.add(n.id);
        }
      }

      _lastId = latest > _lastId ? latest : _lastId;
      setUnread((res['unread_count'] as num?)?.toInt() ?? unread.value);
    } catch (_) {
      // offline / expired session: try again on the next tick
    } finally {
      _busy = false;
    }
  }

  /// Firebase message received while the app is open.
  void handlePush(Map<String, dynamic> data) {
    final n = AppNotification.fromPush(data);
    if (n.title.isEmpty) return;
    if (n.id > 0) {
      if (_shown.contains(n.id)) return;
      _shown.add(n.id);
    }
    unread.value = unread.value + 1;
    present(n);
  }

  /// Plays the sound and shows the animated banner.
  void present(AppNotification n) {
    playSound(n.sound);
    final overlay = navigatorKey?.currentState?.overlay;
    if (overlay == null) return;
    NotificationBanner.show(
      overlay,
      n,
      onTap: () {
        if (n.id > 0) markRead(n.id);
        openInbox?.call();
      },
    );
  }

  Future<void> playSound(String sound) async {
    if (sound == 'none') return;
    try {
      if (sound == 'default') {
        await SystemSound.play(SystemSoundType.alert);
        return;
      }
      await _player.stop();
      await _player.play(AssetSource('sounds/$sound.wav'));
    } catch (e) {
      debugPrint('Notification sound failed: $e');
    }
  }

  Future<void> markRead(int id) async {
    try {
      await ApiClient.instance.post('notifications', {'action': 'mark_read', 'id': id});
      if (unread.value > 0) unread.value = unread.value - 1;
    } catch (_) {}
  }
}
