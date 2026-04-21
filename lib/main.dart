import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arthatrack/screens/auth/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arthatrack/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:arthatrack/services/notification_helper.dart';

void main() async {
  // 1. Wajib ditambahkan jika kita menggunakan fungsi async (seperti SharedPreferences) sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await NotificationHelper.init();

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
      home: isLoggedIn ? const MainScreen() : LoginScreen(),
    );
  }
}
