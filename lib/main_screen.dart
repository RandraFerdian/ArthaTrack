import 'package:flutter/material.dart';
import 'package:arthatrack/screens/dashboard/dashboard_screen.dart';
import 'package:arthatrack/screens/statistic/statistic_screen.dart';
import 'package:arthatrack/screens/profile/profile_screen.dart';
import 'package:arthatrack/screens/target/target_screen.dart';
import 'package:arthatrack/screens/chat/chat_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:arthatrack/services/database_helper.dart';
import 'package:arthatrack/src/core/session_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _profileImagePath = "";

  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  DateTime _lastTiltTime = DateTime.now();

  // [DIUBAH] Dijadikan 'late' agar kita bisa memasukkan fungsi _loadProfileImage
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Inisialisasi daftar halaman dan berikan walkie-talkie ke ProfileScreen
    _pages = [
      DashboardScreen(),
      StatisticScreen(),
      const ChatScreen(),
      const TargetScreen(),
      ProfileScreen(
          onProfileUpdated: _loadProfileImage), // [BARU] Jalur Sinkronisasi
    ];

    _loadProfileImage();
    _initGyroscopeNavigation();
  }

  void _initGyroscopeNavigation() {
    _gyroSubscription =
        gyroscopeEventStream().listen((GyroscopeEvent event) async {
      if (!SessionManager.gyroEnabled) return;

      final now = DateTime.now();
      if (now.difference(_lastTiltTime).inMilliseconds > 1000) {
        if (event.y > 2.5 && _currentIndex < 4) {
          setState(() => _currentIndex++);
          _lastTiltTime = now;
          _loadProfileImage();
        } else if (event.y < -2.5 && _currentIndex > 0) {
          setState(() => _currentIndex--);
          _lastTiltTime = now;
          _loadProfileImage();
        }
      }
    });
  }

  // [DIPERBAIKI] Mengambil foto langsung dari Database SQLite (Sama seperti ProfileScreen)
  Future<void> _loadProfileImage() async {
    int? userId = SessionManager.userId;

    if (userId != null) {
      final userData = await DatabaseHelper.instance.getUserById(userId);
      if (userData != null && mounted) {
        setState(() {
          _profileImagePath = userData['profile_image'] ?? "";
        });
      }
    }
  }

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

  Widget _buildNavItem(IconData icon, String label, int index,
      {bool isProfile = false}) {
    bool isSelected = _currentIndex == index;
    Color activeColor = const Color(0xFF00C853);

    // [BARU] Pengecekan Aman: Apakah string tidak kosong DAN file aslinya benar-benar ada di HP?
    bool hasValidImage =
        _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();

    return GestureDetector(
      onTap: () async {
        setState(() => _currentIndex = index);
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
              child: (isProfile && hasValidImage)
                  // Tampilkan Foto Profil jika kondisinya Valid
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: activeColor, width: 2)
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.transparent,
                        backgroundImage: FileImage(File(_profileImagePath)),
                      ),
                    )
                  // Tampilkan Ikon Default jika kosong atau error
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
                  ? Text(label,
                      style: TextStyle(
                          color: activeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
