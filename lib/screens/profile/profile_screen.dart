import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arthatrack/screens/auth/login_screen.dart';
import 'package:arthatrack/controllers/auth_controller.dart';
import 'package:arthatrack/screens/profile/edit_profile_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:arthatrack/screens/profile/change_password_screen.dart';
// [BARU] Import Database Helper untuk menyimpan Feedback
import 'package:arthatrack/services/database_helper.dart';

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

  // [BARU] State untuk Pengaturan Sensor
  bool _isGyroEnabled = true;
  bool _isAccelEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPreferences(); // Load status sensor
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

  // [BARU] Fungsi mengambil status pengaturan sensor dari memori HP
  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGyroEnabled = prefs.getBool('gyro_enabled') ?? true;
      _isAccelEnabled = prefs.getBool('accel_enabled') ?? true;
    });
  }

  // [BARU] Fungsi menyimpan perubahan toggle Gyroscope
  Future<void> _toggleGyro(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gyro_enabled', value);
    setState(() => _isGyroEnabled = value);
  }

  // [BARU] Fungsi menyimpan perubahan toggle Accelerometer
  Future<void> _toggleAccel(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accel_enabled', value);
    setState(() => _isAccelEnabled = value);
  }

  // [BARU] Fungsi memunculkan form Feedback Matkul Mobile
  void _showFeedbackDialog() {
    final TextEditingController kesanController = TextEditingController();
    final TextEditingController saranController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Feedback Matkul Mobile",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Silakan berikan kesan dan saran Anda terkait proyek dan mata kuliah ini.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: kesanController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Kesan",
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00C853)),
                    borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: saranController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Saran",
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00C853)),
                    borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (kesanController.text.isEmpty ||
                  saranController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Harap isi Kesan dan Saran")));
                return;
              }
              // Simpan ke tabel tpm_feedback di SQLite
              SharedPreferences prefs = await SharedPreferences.getInstance();
              int? userId = prefs.getInt('userId');
              if (userId != null) {
                final db = await DatabaseHelper.instance.database;
                await db.insert('tpm_feedback', {
                  'user_id': userId,
                  'kesan': kesanController.text,
                  'saran': saranController.text,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text("Feedback berhasil dikirim! Terima kasih.")));
                  Navigator.pop(ctx);
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853)),
            child: const Text("Kirim",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false);
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
                      bool? updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                  currentName: _userName,
                                  currentBio: _userBio)));
                      if (updated == true) _loadUserData();
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
                        onChanged: (val) =>
                            setState(() => _isBiometricEnabled = val))),
                _buildDivider(),
                _buildSettingsTile(
                    icon: Icons.lock_outline_rounded,
                    iconColor: Colors.orangeAccent,
                    title: "Ubah PIN / Password",
                    isAction: true,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ChangePasswordScreen()))),
              ],
            ),
            const SizedBox(height: 24),

            // --- 3. EVALUASI & FEEDBACK (PENGGANTI DATA & SINKRONISASI) ---
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
                  onTap: _showFeedbackDialog,
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
                      onChanged: (val) =>
                          setState(() => _isNotificationEnabled = val)),
                ),
                _buildDivider(),
                // [BARU] Toggle Gyroscope
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
