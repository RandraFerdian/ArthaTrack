import 'package:flutter/material.dart';
import 'package:arthatrack/controllers/auth_controller.dart';
import 'package:arthatrack/services/database_helper.dart';
import 'package:arthatrack/src/core/app_routes.dart';
import 'package:arthatrack/src/core/session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
  bool _isBiometricVisible = false; // Flag untuk memunculkan tombol sidik jari

  @override
  void initState() {
    super.initState();
    // [BARU] Memasang pendengar setiap kali user mengetik di kolom username
    _usernameController.addListener(_checkUserBiometricStatus);
    _loadLastUsername();
  }

  Future<void> _loadLastUsername() async {
    String? lastUser = SessionManager.lastUsername;

    if (lastUser != null && lastUser.isNotEmpty) {
      _usernameController.text = lastUser;
    }
  }

  void _checkUserBiometricStatus() async {
    String username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      // [DIUBAH] Gunakan pengecekan berdasarkan 'username', BUKAN 'userId'
      bool isEnabled =
          await DatabaseHelper.instance.checkBiometricByUsername(username);

      if (mounted) {
        setState(() {
          _isBiometricVisible = isEnabled;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isBiometricVisible = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Wajib dihapus agar memori tidak bocor
    _usernameController.removeListener(_checkUserBiometricStatus);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

    String? errorMessage;
    if (_isLogin) {
      errorMessage = await _authController.login(username, password);
    } else {
      errorMessage = await _authController.register(username, password);
    }

    setState(() => _isLoading = false);

    if (errorMessage == null) {
      if (_isLogin) {
        await SessionManager.saveLastUsername(username);
        _showMessage("Selamat Datang, $username!");
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        _showMessage("Registrasi Berhasil! Silakan Login.");
        setState(() {
          _isLogin = true;
          _passwordController.clear();
        });
      }
    } else {
      _showMessage(errorMessage);
    }
  }

  // Aksi saat tombol sidik jari ditekan
  Future<void> _handleBiometric() async {
    String? errorMessage = await _authController.loginWithBiometric();

    if (errorMessage == null) {
      _showMessage("Login Biometrik Berhasil!");
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      _showMessage(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/dark_mode.png',
                height: 320,
                fit: BoxFit.contain,
              ),
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
                    backgroundColor: const Color(0xFF00C853),
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

              // [DIPERBAIKI] Tombol Biometrik dengan Animasi Kemunculan
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: (_isLogin && _isBiometricVisible)
                    ? IconButton(
                        key: const ValueKey('biometric_btn'),
                        iconSize: 50,
                        icon: const Icon(Icons.fingerprint,
                            color: Color(0xFF00C853)),
                        onPressed: _handleBiometric,
                      )
                    : const SizedBox.shrink(key: ValueKey('empty_space')),
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
