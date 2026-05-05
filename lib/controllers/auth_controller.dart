import 'package:local_auth/local_auth.dart';
import 'package:arthatrack/services/database_helper.dart';
import 'package:arthatrack/src/core/session_manager.dart';

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
        int? userId = SessionManager.userId;
        String? username = SessionManager.username;

        if (userId != null && username != null) {
          await _saveSession(userId, username);
          return null; // Sukses
        }
        return "Sesi tidak ditemukan. Silakan login manual dulu.";
      }
      return "Autentikasi biometrik dibatalkan.";
    } catch (e) {
      return "Biometrik error: $e";
    }
  }

  // 4. Logika Menyimpan Session (Private)
  Future<void> _saveSession(int userId, String username) async {
    await SessionManager.saveSession(userId, username);
  }

  // 5. Logika Mengambil Nama User
  Future<String?> getLoggedInUserName() async {
    return SessionManager.username;
  }

  // Logika untuk memperbarui profil user
  Future<String?> updateUserProfile(String newName, String newBio) async {
    try {
      int? userId = SessionManager.userId;

      if (userId != null) {
        await DatabaseHelper.instance
            .updateUserProfile(userId, newName, newBio);
        await SessionManager.saveSession(userId, newName);
        return null; // Sukses, tidak ada error
      }
      return "User ID tidak ditemukan";
    } catch (e) {
      // Jika terjadi error (misalnya username sudah dipakai orang lain)
      return "Gagal menyimpan: Username mungkin sudah digunakan.";
    }
  }

  // --- CARI FUNGSI INI JUGA ---
  Future<void> updateProfileImage(String imagePath) async {
    int? userId = SessionManager.userId;

    if (userId != null) {
      await DatabaseHelper.instance.updateProfileImage(userId, imagePath);
    }
  }

  // [BARU] Logika untuk mengubah password
  Future<String?> changePassword(String oldPassword, String newPassword) async {
    try {
      int? userId = SessionManager.userId;

      if (userId == null)
        return "Sesi user tidak ditemukan. Silakan login ulang.";

      // 1. Ambil data user dari database untuk mencocokkan password lama
      final user = await DatabaseHelper.instance.getUserById(userId);
      if (user == null) return "Data user tidak ditemukan di database.";

      final String oldHashed =
          DatabaseHelper.instance.hashPassword(oldPassword);
      if (user['password'] != oldHashed) {
        return "Password lama yang Anda masukkan salah!";
      }

      await DatabaseHelper.instance.updatePassword(
        userId,
        DatabaseHelper.instance.hashPassword(newPassword),
      );
      return null;
    } catch (e) {
      return "Terjadi kesalahan sistem: $e";
    }
  }

  // [BARU] Ambil Bio/Jurusan
  Future<String> getUserBio() async {
    int? userId = SessionManager.userId;
    if (userId == null) return "-";

    final user = await DatabaseHelper.instance.getUserById(userId);
    return user?['bio'] ?? "-";
  }

  Future<String> getUserProfileImage() async {
    int? userId = SessionManager.userId;
    if (userId == null) return '';

    final user = await DatabaseHelper.instance.getUserById(userId);
    return user?['profile_image'] ?? '';
  }
}
