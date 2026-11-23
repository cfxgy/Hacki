import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/models/models.dart';

class LocalNotificationService {
  Future<void> pushForNewReply(Comment newReply, int storyId) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final Map<String, int> payloadJson = <String, int>{
      'commentId': newReply.id,
      'storyId': storyId,
    };
    final String payload = jsonEncode(payloadJson);

    return flutterLocalNotificationsPlugin.show(
      id: newReply.id,
      title: L10n.current.newReplyNotification,
      body: '${newReply.by}: ${newReply.text}',
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentBadge: false,
          threadIdentifier: 'hacki',
        ),
      ),
      payload: payload,
    );
  }
}
