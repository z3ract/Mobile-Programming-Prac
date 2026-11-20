import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/entities/notification_preference_entity.dart';
import '../../domain/services/i_notification_dispatcher.dart';

/// Platform-aware OS local notification dispatcher with safe runtime detection.
class LocalNotificationDispatcher implements INotificationDispatcher {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const Set<TargetPlatform> _supportedPlatforms = {
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  };

  static const Map<AlertCategory, ({String channelId, String channelName})>
      _channelRegistry = {
    AlertCategory.nowcast: (
      channelId: 'terracast_bmkg_nowcast',
      channelName: 'Peringatan Dini Cuaca BMKG',
    ),
    AlertCategory.rain: (
      channelId: 'terracast_weather_rain',
      channelName: 'Peringatan Hujan & Badai',
    ),
    AlertCategory.heat: (
      channelId: 'terracast_weather_heat',
      channelName: 'Peringatan Suhu Panas',
    ),
    AlertCategory.earthquake: (
      channelId: 'terracast_bmkg_seismic',
      channelName: 'Peringatan Gempa Bumi BMKG',
    ),
    AlertCategory.visibility: (
      channelId: 'terracast_weather_visibility',
      channelName: 'Informasi Jarak Pandang',
    ),
  };

  LocalNotificationDispatcher({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get _isRuntimeSupported =>
      !kIsWeb && _supportedPlatforms.contains(defaultTargetPlatform);

  @override
  Future<void> initialize() async {
    if (_initialized || !_isRuntimeSupported) return;
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Buka TerraCast',
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (e) {
      debugPrint('Notification init notice: $e');
    }
  }

  @override
  Future<bool> requestPermissionIfNeeded() async {
    if (!_isRuntimeSupported) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return (await androidImpl?.requestNotificationsPermission()) ?? true;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return (await iosImpl?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            )) ??
            true;
      }
      return true;
    } catch (e) {
      debugPrint('Notification permission notice: $e');
      return false;
    }
  }

  @override
  Future<void> dispatchAlert(AlertEvaluationEntity alert) async {
    if (!_isRuntimeSupported) return;
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return;

    final channel = _channelRegistry[alert.category] ??
        (
          channelId: 'terracast_general',
          channelName: 'Informasi Cuaca & Gempa',
        );

    final isUrgent = alert.severity == AlertSeverity.danger ||
        alert.severity == AlertSeverity.warning;

    try {
      final androidDetails = AndroidNotificationDetails(
        channel.channelId,
        channel.channelName,
        channelDescription: 'Notifikasi atmosfer dan seismik resmi BMKG',
        importance: isUrgent ? Importance.max : Importance.defaultImportance,
        priority: isUrgent ? Priority.high : Priority.defaultPriority,
      );
      const darwinDetails = DarwinNotificationDetails();
      const linuxDetails = LinuxNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
        linux: linuxDetails,
      );

      await _plugin.show(
        id: alert.id.hashCode & 0x7fffffff,
        title: alert.title,
        body: '${alert.message} ${alert.advice}',
        notificationDetails: details,
        payload: alert.id,
      );
    } catch (e) {
      debugPrint('Notification dispatch notice: $e');
    }
  }
}
