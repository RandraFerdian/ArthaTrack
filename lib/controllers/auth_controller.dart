import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:arthatrack/services/database_helper.dart';

class AuthController {
  final LocalAuthentication auth = LocalAuthentication();

  // 1. Logika Register
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
          await _saveSession(userId, username);
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

  // 5. [DIPERBAIKI] Logika Mengambil Nama User (Sekarang di DALAM class)
  Future<String?> getLoggedInUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // [BARU] Logika untuk memperbarui profil user
  Future<String?> updateUserProfile(String newName, String newBio) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId');

      if (userId != null) {
        // 1. Update di Database SQLite agar bisa dipakai Login
        await DatabaseHelper.instance.updateUser(userId, newName);

        // 2. Update di SharedPreferences untuk tampilan UI
        await prefs.setString('username', newName);
        await prefs.setString('userBio', newBio);

        return null; // Sukses
      }
      return "Sesi user tidak ditemukan";
    } catch (e) {
      return "Gagal memperbarui database: $e";
    }
  }

  // [BARU] Ambil Bio/Jurusan
  Future<String> getUserBio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userBio') ?? "-";
  }

  // ==========================================
  // LOGIKA FOTO PROFIL
  // ==========================================

  // Menyimpan lokasi file foto profil ke memori
  Future<bool> updateProfileImage(String imagePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    if (userId != null) {
      // Simpan dengan kunci unik untuk tiap user, misal: profile_image_1
      return await prefs.setString('profile_image_$userId', imagePath);
    }
    return false;
  }

  // Mengambil lokasi file foto profil
  Future<String> getUserProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    if (userId != null) {
      return prefs.getString('profile_image_$userId') ?? '';
    }
    return '';
  }
}
