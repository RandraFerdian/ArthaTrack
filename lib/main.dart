import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:arthatrack/src/app.dart';
import 'package:arthatrack/src/core/session_manager.dart';
import 'package:arthatrack/services/notification_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await NotificationHelper.init();
  await SessionManager.init();

  runApp(const ArthaTrackApp());
}
