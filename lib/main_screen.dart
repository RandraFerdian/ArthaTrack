import 'package:flutter/material.dart';
import 'package:arthatrack/screens/dashboard/dashboard_screen.dart';
import 'package:arthatrack/screens/statistic/statistic_screen.dart';
import 'package:arthatrack/screens/profile/profile_screen.dart';
import 'package:arthatrack/screens/target/target_screen.dart';
import 'package:arthatrack/screens/chat/chat_screen.dart';
import 'dart:io';
import 'package:arthatrack/controllers/auth_controller.dart';
// [BARU] Import untuk Gyroscope dan Timer
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final AuthController _authController = AuthController();
  String _profileImagePath = ""; // Menyimpan lokasi foto profil untuk Navbar

  // [BARU] Variabel untuk Gyroscope Sensor
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  DateTime _lastTiltTime = DateTime.now();

  final List<Widget> _pages = [
    DashboardScreen(),
    StatisticScreen(),
    const ChatScreen(),
    const TargetScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _initGyroscopeNavigation(); // [BARU] Panggil sensor saat aplikasi dibuka
  }

  // [BARU] Fungsi Logika Sensor Gyroscope
  void _initGyroscopeNavigation() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isGyroEnabled = prefs.getBool('gyro_enabled') ?? true;
    if (!isGyroEnabled) return;
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      final now = DateTime.now();

      // COOLDOWN 1 DETIK: Cegah layar melompat-lompat terlalu cepat
      if (now.difference(_lastTiltTime).inMilliseconds > 1000) {
        // Memiringkan/memutar pergelangan tangan ke KANAN (event.y > 2.5)
        if (event.y > 2.5) {
          if (_currentIndex < 4) {
            // 4 adalah batas akhir (Profil)
            setState(() {
              _currentIndex++;
            });
            _lastTiltTime = now;
            _loadProfileImage(); // Sinkronkan foto profil
          }
        }
        // Memiringkan/memutar pergelangan tangan ke KIRI (event.y < -2.5)
        else if (event.y < -2.5) {
          if (_currentIndex > 0) {
            // 0 adalah batas awal (Home)
            setState(() {
              _currentIndex--;
            });
            _lastTiltTime = now;
            _loadProfileImage(); // Sinkronkan foto profil
          }
        }
      }
    });
  }


  // Mengambil foto profil untuk Navbar
  Future<void> _loadProfileImage() async {
    String imagePath = await _authController.getUserProfileImage();
    if (mounted) {
      setState(() {
        _profileImagePath = imagePath;
      });
    }
  }

  // [BARU] Wajib matikan sensor saat halaman ditutup agar baterai tidak boros
  @override
  void dispose() {
    _gyroSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildFloatingNavbar(),
    );
  }

  Widget _buildFloatingNavbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_rounded, "Home", 0),
          _buildNavItem(Icons.analytics_rounded, "Statistik", 1),
          _buildNavItem(Icons.auto_awesome_rounded, "Chat AI", 2),
          _buildNavItem(Icons.track_changes_rounded, "Target", 3),
          _buildNavItem(Icons.person_rounded, "Profil", 4, isProfile: true),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index, {
    bool isProfile = false,
  }) {
    bool isSelected = _currentIndex == index;
    Color activeColor = const Color(0xFF00C853);

    return GestureDetector(
      onTap: () async {
        setState(() => _currentIndex = index);
        // Selalu muat ulang foto profil saat menu diklik agar otomatis ter-update
        // jika pengguna baru saja mengganti foto di dalam menu Profil
        _loadProfileImage();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(bottom: isSelected ? 4 : 0),
              child: isProfile && _profileImagePath.isNotEmpty
                  // Tampilkan Foto Profil jika ada di tab Profil
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: activeColor, width: 2)
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: 13, // Menyesuaikan ukuran Icon size 26
                        backgroundImage: FileImage(File(_profileImagePath)),
                      ),
                    )
                  // Tampilkan Ikon Biasa
                  : Icon(
                      icon,
                      color: isSelected ? activeColor : Colors.grey,
                      size: 26,
                    ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: isSelected
                  ? Text(
                      label,
                      style: TextStyle(
                        color: activeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
