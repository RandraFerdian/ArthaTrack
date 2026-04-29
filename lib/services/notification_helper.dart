import 'package:flutter/material.dart'; 
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
      'arthatrack_channel_id',
      'ArthaTrack Notifications',
      channelDescription: 'Notifikasi untuk aktivitas transaksi ArthaTrack',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFF00C853),
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  static Future<void> scheduleDailyReminder() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Pengingat Harian',
      channelDescription: 'Mengingatkan user untuk mencatat keuangan',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF00C853),
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.periodicallyShow(
      id: 888, 
      title: 'Waktunya Catat Keuangan! 💸',
      body: 'Jangan sampai ada pengeluaran yang terlewat. Yuk catat sekarang!',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  static Future<void> cancelReminder() async {
    // [DIPERBAIKI] Menggunakan Named Parameters
    await _notificationsPlugin.cancel(id: 888);
  }
}
