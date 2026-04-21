import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arthatrack/screens/auth/login_screen.dart';
import 'package:arthatrack/controllers/auth_controller.dart';
import 'package:arthatrack/screens/profile/edit_profile_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = AuthController();

  String _userName = "Memuat...";
  String _userBio = "Memuat...";
  String _profileImagePath = "";

  bool _isBiometricEnabled = true;
  bool _isNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? name = await _authController.getLoggedInUserName();
    String bio = await _authController.getUserBio();
    String imagePath = await _authController.getUserProfileImage();

    setState(() {
      _userName = name ?? "-";
      _userBio = bio;
      _profileImagePath = imagePath;
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Keluar dari ArthaTrack?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Sesi Anda akan diakhiri dan Anda harus login kembali.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false); // Bersihkan sesi

              if (!mounted) return;
              // Tendang ke halaman Login dan hapus semua riwayat rute (backstack)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "Keluar",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Membuka galeri HP
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Jika berhasil pilih foto, simpan ke memori dan update layar
      await _authController.updateProfileImage(image.path);
      setState(() {
        _profileImagePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Profil & Pengaturan",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. KARTU PROFIL HEADER ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00C853).withOpacity(0.2),
                            border: Border.all(
                              color: const Color(0xFF00C853),
                              width: 2,
                            ),
                            // [BARU] Menampilkan gambar jika path tidak kosong
                            image: _profileImagePath.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(File(_profileImagePath)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImagePath.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF00C853),
                                    size: 36,
                                  ),
                                )
                              : null,
                        ),
                        // Ikon kamera kecil di pojok
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2962FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          // [DIPERBAIKI] Menggunakan variabel _userBio dinamis bukan teks statis
                          child: Text(
                            _userBio,
                            style: const TextStyle(
                              color: Color(0xFF82B1FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_square, color: Colors.grey),
                    onPressed: () async {
                      // Navigasi ke Edit Profil dan tunggu hasilnya
                      bool? updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            currentName: _userName,
                            currentBio:
                                _userBio, // Sekarang variabel ini sudah dikenali
                          ),
                        ),
                      );
                      if (updated == true) {
                        _loadUserData(); // Refresh data jika sukses simpan
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- 2. AKUN & KEAMANAN ---
            const Text(
              "Akun & Keamanan",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsContainer(
              children: [
                _buildSettingsTile(
                  icon: Icons.fingerprint_rounded,
                  iconColor: const Color(0xFF00C853),
                  title: "Login Biometrik",
                  subtitle: "Gunakan sidik jari untuk masuk",
                  trailing: Switch(
                    value: _isBiometricEnabled,
                    activeColor: const Color(0xFF00C853),
                    onChanged: (val) =>
                        setState(() => _isBiometricEnabled = val),
                  ),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: Colors.orangeAccent,
                  title: "Ubah PIN / Password",
                  isAction: true,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 3. DATA & SINKRONISASI ---
            const Text(
              "Data & Sinkronisasi",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsContainer(
              children: [
                _buildSettingsTile(
                  icon: Icons.cloud_sync_rounded,
                  iconColor: const Color(0xFF2962FF),
                  title: "Cloud Sync & Backup",
                  subtitle: "Cadangkan data SQLite ke Cloud",
                  isAction: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Menghubungkan ke server GCP..."),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.download_rounded,
                  iconColor: Colors.tealAccent,
                  title: "Export Laporan (.CSV / PDF)",
                  isAction: true,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 4. PREFERENSI APLIKASI ---
            const Text(
              "Preferensi",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsContainer(
              children: [
                _buildSettingsTile(
                  icon: Icons.notifications_active_rounded,
                  iconColor: Colors.amber,
                  title: "Notifikasi Pengingat",
                  trailing: Switch(
                    value: _isNotificationEnabled,
                    activeColor: const Color(0xFF00C853),
                    onChanged: (val) =>
                        setState(() => _isNotificationEnabled = val),
                  ),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: Colors.purpleAccent,
                  title: "Bahasa",
                  trailing: const Text(
                    "Indonesia",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- 5. TOMBOL LOGOUT ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  "Keluar dari Akun",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252).withOpacity(0.8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- 6. FOOTER ---
            const Center(
              child: Column(
                children: [
                  Text(
                    "ArthaTrack v1.0.0",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Made with ♥ for Financial Freedom",
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Ruang untuk navbar bawah
          ],
        ),
      ),
    );
  }

  // WIDGET BANTUAN UNTUK MEMBUAT KOTAK KELOMPOK MENU
  Widget _buildSettingsContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  // WIDGET BANTUAN UNTUK BARIS MENU
  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool isAction = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? (isAction ? () {} : null),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (isAction && trailing == null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET BANTUAN UNTUK GARIS PEMISAH
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      height: 1,
      color: Colors.white10,
    );
  }
}
