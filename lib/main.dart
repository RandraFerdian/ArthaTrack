import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arthatrack/screens/auth/login_screen.dart';
import 'package:arthatrack/screens/dashboard/dashboard_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  // 1. Wajib ditambahkan jika kita menggunakan fungsi async (seperti SharedPreferences) sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Cek apakah ada session yang tersimpan
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // 3. Jalankan aplikasi dan kirim status login-nya
  runApp(ArthaTrackApp(isLoggedIn: isLoggedIn));
}

class ArthaTrackApp extends StatelessWidget {
  final bool isLoggedIn;

  const ArthaTrackApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArthaTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00C853),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00C853),
          secondary: Color(0xFF1A237E),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
      ),
      home: isLoggedIn ? DashboardScreen() : LoginScreen(),
    );
  }
}
