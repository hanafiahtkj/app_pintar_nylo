import 'dart:io';

import '/app/events/notification_refresh_event.dart';
import '/app/networking/pintar_api_service.dart';
import '/config/storage_keys.dart';
import '/resources/pages/notification_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

const String _channelIdDefault = 'default_channel';
const String _channelIdForeground = 'fcm_foreground_channel';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {
      return;
    }

    await _initLocalNotifications();
    _onTokenRefresh();
    _onMessageHandler();
    _onMessageOpenedApp();
    _getInitialMessage();

    _requestPermission().then((_) async {
      await _getFCMToken();
      final enabled =
          await StorageKeysConfig.pushNotificationsEnabled.read<bool>() ?? true;
      if (enabled) {
        await subscribeToAllTopic();
      }
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) => _navigateToNotification(),
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdDefault,
          'Default Channel',
          description: 'Default notification channel',
          importance: Importance.high,
          playSound: true,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdForeground,
          'FCM Foreground',
          description: 'Notifikasi foreground FCM',
          importance: Importance.high,
          playSound: true,
        ),
      );
    }
  }

  Future<void> _requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: true,
        );
      }
    } catch (_) {}
  }

  Future<void> ensurePermission() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        await _requestPermission();
      }
    } catch (_) {}
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await registerTokenToBackend(token);
      }
    } catch (_) {}
  }

  void _onTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      registerTokenToBackend(newToken);
    });
  }

  void _onMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      event<NotificationRefreshEvent>(broadcast: true);

      final notification = message.notification;
      if (notification != null) {
        _showForegroundNotification(
          title: notification.title ?? 'Notifikasi',
          body: notification.body ?? '',
        );
      }
    });
  }

  Future<void> _showForegroundNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelIdForeground,
      'FCM Foreground',
      channelDescription: 'Notifikasi foreground FCM',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  void _onMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateToNotification();
    });
  }

  Future<void> _getInitialMessage() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToNotification();
        });
      }
    } catch (_) {}
  }

  void _navigateToNotification() {
    event<NotificationRefreshEvent>(broadcast: true);
    routeTo(NotificationPage.path);
  }

  Future<void> registerTokenToBackend(String token) async {
    try {
      await api<PintarApiService>(
        (request) => request.registerDeviceToken(token),
      );
    } catch (_) {}
  }

  Future<void> refreshTokenRegistration() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await registerTokenToBackend(token);
      }
    } catch (_) {}
  }

  Future<void> subscribeToAllTopic() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all');
    } catch (_) {}
  }

  Future<void> unsubscribeFromAllTopic() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('all');
    } catch (_) {}
  }

  Future<void> handleNotificationToggle(bool enabled) async {
    await StorageKeysConfig.pushNotificationsEnabled.save(
      enabled,
      inBackpack: true,
    );
    if (enabled) {
      await subscribeToAllTopic();
    } else {
      await unsubscribeFromAllTopic();
    }
  }
}

class FirebaseMessagingProvider implements NyProvider {
  @override
  Future<Nylo?> setup(Nylo nylo) async {
    return nylo;
  }

  @override
  Future<void> boot(Nylo nylo) async {
    FirebaseMessagingService().initialize();
  }
}
