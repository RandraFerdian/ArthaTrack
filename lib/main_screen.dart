import 'package:flutter/material.dart';
import 'package:arthatrack/screens/dashboard/dashboard_screen.dart';
import 'package:arthatrack/screens/transaction/transaction_history_screen.dart'; // Bisa digunakan untuk Statistik sementara
// Import halaman lainnya nanti (Chat AI, Target, Profil)

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Daftar halaman sesuai urutan menu
  final List<Widget> _pages = [
    DashboardScreen(),
    const Center(
      child: Text("Halaman Statistik"),
    ), // Ganti dengan Screen Statistik nanti
    const Center(
      child: Text("Halaman Chat AI"),
    ), // Ganti dengan Screen Chat AI nanti
    const Center(
      child: Text("Halaman Target"),
    ), // Ganti dengan Screen Target nanti
    const Center(
      child: Text("Halaman Profil"),
    ), // Ganti dengan Screen Profil nanti
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      // ExtendBody membuat konten mengalir di belakang navbar yang transparan
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildFloatingNavbar(),
    );
  }

  Widget _buildFloatingNavbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 70, // Tinggi tetap
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
      // Menggunakan Row biasa agar presisi dan mudah diatur
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_rounded, "Home", 0),
          _buildNavItem(Icons.analytics_rounded, "Statistik", 1),
          _buildNavItem(Icons.auto_awesome_rounded, "Chat AI", 2),
          _buildNavItem(Icons.track_changes_rounded, "Target", 3),
          _buildNavItem(Icons.person_rounded, "Profil", 4),
        ],
      ),
    );
  }

  // Widget khusus untuk mengatur setiap menu agar presisi di tengah
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    Color activeColor = const Color(0xFF00C853);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior
          .opaque, // Agar area kosong di sekitarnya tetap bisa diklik
      child: SizedBox(
        width: 60, // Memberikan ruang lebar yang sama untuk tiap menu
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // KUNCI: Membuatnya center atas-bawah
          mainAxisSize: MainAxisSize.max,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              // Jika dipilih, ikon sedikit naik, jika tidak, berada tepat di tengah
              margin: EdgeInsets.only(bottom: isSelected ? 4 : 0),
              child: Icon(
                icon,
                color: isSelected ? activeColor : Colors.grey,
                size: 26,
              ),
            ),
            // Menggunakan AnimatedOpacity agar teks muncul memudar secara elegan
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
