import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arthatrack/controllers/auth_controller.dart';
import 'package:arthatrack/services/database_helper.dart';
import 'package:arthatrack/services/notification_helper.dart';
import 'package:arthatrack/src/core/app_routes.dart';
import 'package:arthatrack/src/core/session_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onProfileUpdated});
  final VoidCallback? onProfileUpdated;

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
  bool _isGyroEnabled = true;
  bool _isAccelEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPreferences();
  }

  Future<void> _loadUserData() async {
    int? userId = SessionManager.userId;

    if (userId != null) {
      final userData = await DatabaseHelper.instance.getUserById(userId);

      if (userData != null && mounted) {
        setState(() {
          _userName = userData['username'] ?? "User";
          _userBio = userData['bio'] ?? "Belum ada bio";
          _profileImagePath = userData['profile_image'] ?? "";
        });
      }
    }
  }

  Future<void> _loadPreferences() async {
    int? userId = SessionManager.userId;
    bool bioStatus = false;
    if (userId != null) {
      bioStatus = await DatabaseHelper.instance.isBiometricEnabled(userId);
    }

    if (mounted) {
      setState(() {
        _isGyroEnabled = SessionManager.gyroEnabled;
        _isAccelEnabled = SessionManager.prefs.getBool('accel_enabled') ?? true;
        _isNotificationEnabled = SessionManager.notificationEnabled;
        _isBiometricEnabled = bioStatus;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    int? userId = SessionManager.userId;
    if (userId != null) {
      await DatabaseHelper.instance.updateBiometricStatus(userId, value);
    }
    setState(() => _isBiometricEnabled = value);
  }

  Future<void> _toggleNotification(bool value) async {
    await SessionManager.setNotificationEnabled(value);
    setState(() => _isNotificationEnabled = value);

    if (value) {
      await NotificationHelper.scheduleDailyReminder();
    } else {
      await NotificationHelper.cancelReminder();
    }
  }

  Future<void> _toggleGyro(bool value) async {
    await SessionManager.setGyroEnabled(value);
    setState(() => _isGyroEnabled = value);
  }

  Future<void> _toggleAccel(bool value) async {
    await SessionManager.setAccelEnabled(value);
    setState(() => _isAccelEnabled = value);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Keluar dari ArthaTrack?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            "Sesi Anda akan diakhiri dan Anda harus login kembali.",
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("Batal", style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () async {
              await SessionManager.clearSession();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text("Keluar",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _authController.updateProfileImage(image.path);
      setState(() => _profileImagePath = image.path);
      widget.onProfileUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Profil & Pengaturan",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
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
                    end: Alignment.bottomRight),
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
                                color: const Color(0xFF00C853), width: 2),
                            image: _profileImagePath.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(File(_profileImagePath)),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: _profileImagePath.isEmpty
                              ? const Center(
                                  child: Icon(Icons.person_rounded,
                                      color: Color(0xFF00C853), size: 36))
                              : null,
                        ),
                        Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: Color(0xFF00C853),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFF2962FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(_userBio,
                              style: const TextStyle(
                                  color: Color(0xFF82B1FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_square, color: Colors.grey),
                    onPressed: () async {
                      bool? updated = await Navigator.pushNamed(
                        context,
                        AppRoutes.editProfile,
                        arguments: {
                          'currentName': _userName,
                          'currentBio': _userBio,
                        },
                      );
                      if (updated == true) _loadUserData();
                      widget.onProfileUpdated?.call();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- 2. AKUN & KEAMANAN ---
            const Text("Akun & Keamanan",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
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
                        onChanged: _toggleBiometric)),
                _buildDivider(),
                _buildSettingsTile(
                    icon: Icons.lock_outline_rounded,
                    iconColor: Colors.orangeAccent,
                    title: "Ubah PIN / Password",
                    isAction: true,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.changePassword)),
              ],
            ),
            const SizedBox(height: 24),

            // --- 3. EVALUASI & FEEDBACK  ---
            const Text("Evaluasi Proyek",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildSettingsContainer(
              children: [
                _buildSettingsTile(
                  icon: Icons.feedback_rounded,
                  iconColor: const Color(0xFF2962FF),
                  title: "Feedback Matkul Mobile",
                  subtitle: "Berikan kesan & saran untuk TPM",
                  isAction: true,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.feedback);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 4. PREFERENSI APLIKASI ---
            const Text("Preferensi & Sensor",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
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
                      onChanged: _toggleNotification),
                ),
                _buildDivider(),

                _buildSettingsTile(
                  icon: Icons.screen_rotation_rounded,
                  iconColor: Colors.cyanAccent,
                  title: "Gyroscope Navigasi",
                  subtitle: "Miringkan HP pindah menu",
                  trailing: Switch(
                      value: _isGyroEnabled,
                      activeColor: const Color(0xFF00C853),
                      onChanged: _toggleGyro),
                ),
                _buildDivider(),
                // [BARU] Toggle Accelerometer
                _buildSettingsTile(
                  icon: Icons.vibration_rounded,
                  iconColor: Colors.pinkAccent,
                  title: "Shake to Refresh",
                  subtitle: "Goyangkan HP untuk update",
                  trailing: Switch(
                      value: _isAccelEnabled,
                      activeColor: const Color(0xFF00C853),
                      onChanged: _toggleAccel),
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
                label: const Text("Keluar dari Akun",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5252).withOpacity(0.8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContainer({required List<Widget> children}) {
    return Container(
        decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20)),
        child: Column(children: children));
  }

  Widget _buildSettingsTile(
      {required IconData icon,
      required Color iconColor,
      required String title,
      String? subtitle,
      Widget? trailing,
      bool isAction = false,
      VoidCallback? onTap}) {
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
                      shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12))
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (isAction && trailing == null)
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.grey, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 50),
        height: 1,
        color: Colors.white10);
  }
}
