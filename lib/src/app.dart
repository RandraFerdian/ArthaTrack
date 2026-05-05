import 'package:flutter/material.dart';
import 'package:arthatrack/src/core/app_routes.dart';
import 'package:arthatrack/src/core/app_theme.dart';
import 'package:arthatrack/src/core/session_manager.dart';

class ArthaTrackApp extends StatelessWidget {
  const ArthaTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArthaTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialRoute:
          SessionManager.isLoggedIn ? AppRoutes.home : AppRoutes.login,
      onGenerateRoute: AppRoutes.generate,
    );
  }
}
