import 'package:flutter/material.dart'; // [BARU] Import ini wajib ada agar kode Color dikenali
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Pengaturan ikon notifikasi untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Pengaturan untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // [DIPERBAIKI] Versi terbaru mewajibkan pemanggilan dengan named parameter (settings:)
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Meminta izin notifikasi untuk pengguna Android 13+
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Fungsi untuk memunculkan notifikasi
  static Future<void> showTransactionNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'arthatrack_channel_id', // ID Channel
      'ArthaTrack Notifications', // Nama Channel
      channelDescription: 'Notifikasi untuk aktivitas transaksi ArthaTrack',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(
          0xFF00C853), // [DIPERBAIKI] Typo dihapus (sebelumnya Colors jadi Color)
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // [DIPERBAIKI] Versi terbaru mewajibkan named parameters (id:, title:, body:, notificationDetails:)
    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}
