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

  // 5. Logika Mengambil Nama User
  Future<String?> getLoggedInUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // Logika untuk memperbarui profil user
  Future<String?> updateUserProfile(String newName, String newBio) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId');

      if (userId != null) {
        // [WAJIB ADA] Simpan ke Database!
        await DatabaseHelper.instance
            .updateUserProfile(userId, newName, newBio);

        // (Opsional) Boleh tetap disimpan di SharedPreferences juga jika mau
        await prefs.setString('username', newName);
        await prefs.setString('user_bio', newBio);

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    if (userId != null) {
      // [WAJIB ADA] Simpan ke Database!
      await DatabaseHelper.instance.updateProfileImage(userId, imagePath);
    }
  }

  // [BARU] Logika untuk mengubah password
  Future<String?> changePassword(String oldPassword, String newPassword) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId');

      if (userId == null)
        return "Sesi user tidak ditemukan. Silakan login ulang.";

      // 1. Ambil data user dari database untuk mencocokkan password lama
      final user = await DatabaseHelper.instance.getUserById(userId);
      if (user == null) return "Data user tidak ditemukan di database.";

      // 2. Verifikasi apakah password lama yang dimasukkan benar
      if (user['password'] != oldPassword) {
        return "Password lama yang Anda masukkan salah!";
      }

      // 3. Jika benar, update dengan password baru
      await DatabaseHelper.instance.updatePassword(userId, newPassword);
      return null;
    } catch (e) {
      return "Terjadi kesalahan sistem: $e";
    }
  }

  // [BARU] Ambil Bio/Jurusan
  Future<String> getUserBio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userBio') ?? "-";
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
