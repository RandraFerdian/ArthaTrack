import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arthatrack/services/database_helper.dart';

class FinanceController {
  // ==========================================
  // FUNGSI BANTUAN (PRIVATE)
  // ==========================================

  // Mengambil ID User yang sedang login dari Session
  Future<int?> _getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  // Meminta izin dan mengambil koordinat GPS saat ini
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition();
  }

  // ==========================================
  // LOGIKA TRANSAKSI (DOMPET)
  // ==========================================

  // 1. Tambah Transaksi (Income / Expense) + LBS
  Future<String?> addTransaction({
    required String title,
    required double amount,
    required String type,
    required String category,
  }) async {
    try {
      int? userId = await _getCurrentUserId();
      if (userId == null) return "Sesi tidak ditemukan. Silakan login ulang.";
      Position? position = await _getCurrentLocation();
      final transactionData = {
        'user_id': userId,
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'date': DateTime.now().toIso8601String(),
        'latitude': position?.latitude,
        'longitude': position?.longitude,
      };

      await DatabaseHelper.instance.addTransaction(transactionData);
      return null;
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  // 2. Ambil Riwayat Transaksi User Saat Ini
  Future<List<Map<String, dynamic>>> getUserTransactions() async {
    int? userId = await _getCurrentUserId();
    if (userId == null) return [];
    return await DatabaseHelper.instance.getTransactionsByUser(userId);
  }

  // 3. Ambil Total Saldo User Saat Ini
  Future<double> getTotalBalance() async {
    int? userId = await _getCurrentUserId();
    if (userId == null) return 0.0;
    return await DatabaseHelper.instance.calculateTotalBalance(userId);
  }

  // 4. Hapus Transaksi
  Future<bool> deleteTransaction(int transactionId) async {
    int result = await DatabaseHelper.instance.deleteTransaction(transactionId);
    return result > 0; // Return true jika berhasil dihapus
  }

  // ==========================================
  // LOGIKA TARGET TABUNGAN (SAVINGS GOALS)
  // ==========================================

  // 1. Buat Target Tabungan Baru
  Future<String?> addSavingsGoal(
    String goalName,
    double targetAmount,
    String deadline,
  ) async {
    try {
      int? userId = await _getCurrentUserId();
      if (userId == null) return "Error: Sesi tidak ditemukan.";

      final goalData = {
        'user_id': userId,
        'goal_name': goalName,
        'target_amount': targetAmount,
        'current_amount': 0.0,
        'deadline': deadline,
      };

      await DatabaseHelper.instance.addSavingsGoal(goalData);
      return null;
    } catch (e) {
      return "Gagal membuat target: $e";
    }
  }

  // 2. Ambil Daftar Target Tabungan
  Future<List<Map<String, dynamic>>> getUserSavingsGoals() async {
    int? userId = await _getCurrentUserId();
    if (userId == null) return [];
    return await DatabaseHelper.instance.getSavingsGoalsByUser(userId);
  }

  // 3. Nabung ke Target (Tambah Progress)
  Future<bool> addMoneyToGoal(int goalId, double amount) async {
    int result = await DatabaseHelper.instance.addMoneyToGoal(goalId, amount);
    return result > 0;
  }
}
