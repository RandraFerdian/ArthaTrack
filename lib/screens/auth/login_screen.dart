import 'package:arthatrack/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:arthatrack/controllers/auth_controller.dart';
import 'package:arthatrack/screens/dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Fungsi untuk menampilkan pop-up pesan
  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Aksi saat tombol utama ditekan
  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage("Username dan Password tidak boleh kosong!");
      setState(() => _isLoading = false);
      return;
    }

    // Panggil logika dari AuthController
    String? errorMessage;
    if (_isLogin) {
      errorMessage = await _authController.login(username, password);
    } else {
      errorMessage = await _authController.register(username, password);
    }

    // Tanggapan dari logika (Output)
    setState(() => _isLoading = false);

    if (errorMessage == null) {
      // Jika null berarti SUKSES
      if (_isLogin) {
        _showMessage("Selamat Datang, $username!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        _showMessage("Registrasi Berhasil! Silakan Login.");
        setState(() {
          _isLogin = true;
          _passwordController.clear();
        });
      }
    } else {
      // Jika ada isi pesannya berarti ERROR
      _showMessage(errorMessage);
    }
  }

  // Aksi saat tombol sidik jari ditekan
  Future<void> _handleBiometric() async {
    String? errorMessage = await _authController.loginWithBiometric();

    if (errorMessage == null) {
      _showMessage("Login Biometrik Berhasil!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      _showMessage(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan tema gelap sesuai kesepakatan
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau Icon Aplikasi
              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Color(0xFF00C853),
              ),
              const SizedBox(height: 16),
              const Text(
                "ArthaTrack",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? "Silakan login untuk melanjutkan" : "Buat akun baru",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Form Input Username
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Form Input Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Utama (Login / Register)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853), // Accent Green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isLogin ? "LOGIN" : "REGISTER",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Biometrik (Hanya muncul saat Login)
              if (_isLogin)
                IconButton(
                  iconSize: 50,
                  icon: const Icon(Icons.fingerprint, color: Color(0xFF00C853)),
                  onPressed: _handleBiometric,
                ),

              // Toggle Mode Login/Register
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _passwordController.clear();
                  });
                },
                child: Text(
                  _isLogin
                      ? "Belum punya akun? Register di sini"
                      : "Sudah punya akun? Login di sini",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
