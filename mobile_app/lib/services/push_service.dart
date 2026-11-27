import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'notification_center.dart';

/// Runs in its own isolate when a push arrives while the app is closed.
/// Messages carry a `notification` block, so Android shows them (with the channel's sound) itself.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// Phone push notifications (Firebase Cloud Messaging).
///
/// Everything is optional: until `google-services.json` is added to the Android project the
/// app simply skips Firebase and still gets in-app notifications with sound through
/// [NotificationCenter] polling.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const _promptedKey = 'push_prompted_v1';
  static const _appVersion = '1.0.0';

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _firebaseReady = false;
  String? _token;
  bool _openInboxAfterStart = false;

  bool get isReady => _firebaseReady;

  Future<void> init() async {
    if (kIsWeb) return;

    await _createAndroidChannels();

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase not configured, phone push disabled: $e');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      // The in-app banner handles foreground messages; stop iOS from showing a duplicate.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      FirebaseMessaging.onMessage.listen((m) {
        final data = Map<String, dynamic>.from(m.data);
        data['title'] ??= m.notification?.title ?? '';
        data['message'] ??= m.notification?.body ?? '';
        NotificationCenter.instance.handlePush(data);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((_) => NotificationCenter.instance.openInbox?.call());
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        _token = t;
        _registerToken(t);
      });
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _openInboxAfterStart = true;
    } catch (e) {
      debugPrint('Push setup failed: $e');
    }

    ApiClient.instance.beforeLogout = unregister;
  }

  /// Android 8+: one channel per sound (sound is bound to the channel, so it must exist up front).
  Future<void> _createAndroidChannels() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;

      AndroidNotificationChannel ch(String id, String name, String desc, {String? sound}) =>
          AndroidNotificationChannel(
            id,
            name,
            description: desc,
            importance: Importance.max,
            playSound: sound != null || id == 'paddy_default',
            sound: sound == null ? null : RawResourceAndroidNotificationSound(sound),
            enableVibration: true,
          );

      for (final c in [
        ch('paddy_coins', 'Payments & profit (coin sound)', 'Deposits, profit and payment alerts', sound: 'coins'),
        ch('paddy_bell', 'Announcements (bell)', 'Offers and announcements', sound: 'bell'),
        ch('paddy_success', 'Success (chime)', 'Approvals and confirmations', sound: 'success'),
        ch('paddy_default', 'General', 'Other notifications'),
      ]) {
        await android.createNotificationChannel(c);
      }
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'paddy_silent',
          'Silent',
          description: 'Notifications without sound',
          importance: Importance.defaultImportance,
          playSound: false,
          enableVibration: false,
        ),
      );
    } catch (e) {
      debugPrint('Creating notification channels failed: $e');
    }
  }

  /// Call after sign-in: asks for permission (once, with a friendly explanation) and
  /// registers this phone for push.
  Future<void> onSignedIn(BuildContext context) async {
    if (_openInboxAfterStart) {
      _openInboxAfterStart = false;
      NotificationCenter.instance.openInbox?.call();
    }
    if (!_firebaseReady) return;
    try {
      final messaging = FirebaseMessaging.instance;
      var settings = await messaging.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool(_promptedKey) ?? false)) {
          if (!context.mounted) return;
          final go = await _showPrePrompt(context);
          await prefs.setBool(_promptedKey, true);
          if (go != true) return;
        }
        settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      }

      final ok = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!ok) return;

      final token = await messaging.getToken();
      if (token != null) {
        _token = token;
        await _registerToken(token);
      }
    } catch (e) {
      debugPrint('Push sign-in setup failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    if (!ApiClient.instance.isLoggedIn) return;
    try {
      await ApiClient.instance.post('push-token', {
        'action': 'register',
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'device_name': defaultTargetPlatform.name,
        'app_version': _appVersion,
      });
    } catch (e) {
      debugPrint('Push token registration failed: $e');
    }
  }

  /// Detach this phone from the account so the next user doesn't receive these notifications.
  Future<void> unregister() async {
    final t = _token;
    if (t == null || !ApiClient.instance.isLoggedIn) return;
    try {
      await ApiClient.instance.post('push-token', {'action': 'unregister', 'token': t});
    } catch (_) {}
  }

  Future<bool?> _showPrePrompt(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF3C4), Color(0xFFF0C040)],
                  ),
                ),
                child: const Icon(Icons.notifications_active_rounded, size: 40, color: Color(0xFF006B3C)),
              ),
              const SizedBox(height: 18),
              const Text(
                'Never miss a payout',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Turn on notifications to hear a coin chime the moment your deposit is confirmed, '
                'profit is credited, or we have a new offer for you.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Enable notifications'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006B3C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
