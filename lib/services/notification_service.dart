import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Inicializa o plugin de notificações. Deve ser chamado em main() antes de runApp().
  /// A solicitação de permissão NÃO é feita aqui — use [requestPermission] depois
  /// do primeiro frame renderizado para evitar travamento no Android 15+.
  static Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
  }

  /// Solicita permissão de notificação ao usuário.
  /// Deve ser chamado APÓS runApp(), quando o app já tem uma Activity ativa.
  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleReminder({
    required int id,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) return;

    // Converte para UTC para garantir horário correto independente do fuso
    final tzScheduled = tz.TZDateTime.from(scheduledDate.toUtc(), tz.UTC);

    await _plugin.zonedSchedule(
      id,
      'Konta — Lembrete',
      body,
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'konta_reminders',
          'Lembretes',
          channelDescription: 'Lembretes do Konta',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  static int idFromUuid(String uuid) => uuid.hashCode.abs() % 2147483647;
}
