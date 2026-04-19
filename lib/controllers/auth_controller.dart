import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:arthatrack/services/database_helper.dart';

class AuthController {
  final LocalAuthentication auth = LocalAuthentication();

  // 1. Logika Register
  // Mengembalikan nilai 'null' jika sukses, atau pesan error (String) jika gagal.
  Future<String?> register(String username, String password) async {
    try {
      final newUserId = await DatabaseHelper.instance.registerUser(
        username,
        password,
      );
      if (newUserId != 0) {
        return null; // Sukses
      } else {
        return "Username sudah terdaftar!"; // Gagal
      }
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  // 2. Logika Login Manual
  Future<String?> login(String username, String password) async {
    try {
      final user = await DatabaseHelper.instance.loginUser(username, password);
      if (user != null) {
        await _saveSession(user['id'], user['username']);
        return null; // Sukses
      } else {
        return "Username atau Password salah!"; // Gagal
      }
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  // 3. Logika Login Biometrik
  Future<String?> loginWithBiometric() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (!canCheckBiometrics) return "Perangkat tidak mendukung biometrik.";

      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Scan sidik jari untuk masuk ke ArthaTrack',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (didAuthenticate) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int? userId = prefs.getInt('userId');
        String? username = prefs.getString('username');

        if (userId != null && username != null) {
          await _saveSession(userId!, username!);
          return null; // Sukses
        } else {
          return "Sesi tidak ditemukan. Silakan login manual dulu.";
        }
      } else {
        return "Autentikasi biometrik dibatalkan.";
      }
    } catch (e) {
      return "Biometrik error: $e";
    }
  }

  // 4. Logika Menyimpan Session (Private)
  Future<void> _saveSession(int userId, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('userId', userId);
    await prefs.setString('username', username);
  }
}
