import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arthatrack/services/database_helper.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FinanceController {
  // ==========================================
  // FUNGSI BANTUAN (PRIVATE)
  // ==========================================

  Future<int?> _getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

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

  // [DIPERBAIKI] Tambah transaksi sekarang mendukung input tanggal bebas
  Future<String?> addTransaction({
    required String title,
    required double amount,
    required String type,
    required String category,
    String? date, // Tanggal opsional
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
        'date': date ??
            DateTime.now()
                .toIso8601String(), // Gunakan tanggal input atau hari ini
        'latitude': position?.latitude,
        'longitude': position?.longitude,
      };

      await DatabaseHelper.instance.addTransaction(transactionData);
      return null;
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  // [BARU] Logika untuk Edit Transaksi (Update)
  Future<String?> updateTransaction({
    required int id,
    required String title,
    required double amount,
    required String type,
    required String category,
    required String date,
  }) async {
    try {
      final transactionData = {
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'date': date,
      };

      await DatabaseHelper.instance.updateTransaction(id, transactionData);
      return null;
    } catch (e) {
      return "Gagal memperbarui transaksi: $e";
    }
  }

  Future<List<Map<String, dynamic>>> getUserTransactions() async {
    int? userId = await _getCurrentUserId();
    if (userId == null) return [];
    return await DatabaseHelper.instance.getTransactionsByUser(userId);
  }

  Future<double> getTotalBalance() async {
    int? userId = await _getCurrentUserId();
    if (userId == null) return 0.0;
    return await DatabaseHelper.instance.calculateTotalBalance(userId);
  }

  Future<bool> deleteTransaction(int transactionId) async {
    int result = await DatabaseHelper.instance.deleteTransaction(transactionId);
    return result > 0;
  }

  // ==========================================
  // LOGIKA TARGET TABUNGAN (SAVINGS GOALS)
  // ==========================================

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

  Future<List<Map<String, dynamic>>> getUserSavingsGoals() async {
    int? userId = await _getCurrentUserId();
    if (userId == null) return [];
    return await DatabaseHelper.instance.getSavingsGoalsByUser(userId);
  }

  // [DIPERBAIKI] Menyambungkan Target dengan Saldo Utama
  Future<bool> addMoneyToGoal(
    int goalId,
    double amount,
    String goalName,
  ) async {
    try {
      // 1. Cek dulu apakah Saldo Utama cukup!
      double totalBalance = await getTotalBalance();
      if (totalBalance < amount) {
        throw Exception(
          "Saldo utama tidak mencukupi untuk menabung sebesar itu.",
        );
      }

      // 2. Tambahkan uang ke tabel target
      int result = await DatabaseHelper.instance.addMoneyToGoal(goalId, amount);

      // 3. Jika berhasil, otomatis potong saldo utama (Catat sebagai pengeluaran)
      if (result > 0) {
        await addTransaction(
          title:
              "Alokasi Target: $goalName", // Nama transaksi yang muncul di riwayat
          amount: amount,
          type:
              'expense', // Dihitung sebagai pengeluaran agar saldo utama berkurang
          category: 'Investasi', // Masuk kategori investasi/tabungan
          date: DateTime.now().toIso8601String(),
        );
        return true;
      }
      return false;
    } catch (e) {
      // Lempar error agar bisa ditangkap oleh UI (SnackBar)
      throw Exception(e.toString());
    }
  }

  Future<String?> updateSavingsGoal(
    int id,
    String goalName,
    double targetAmount,
    String deadline,
  ) async {
    try {
      await DatabaseHelper.instance.updateSavingsGoal(id, {
        'goal_name': goalName,
        'target_amount': targetAmount,
        'deadline': deadline,
      });
      return null;
    } catch (e) {
      return "Gagal memperbarui target: $e";
    }
  }

  Future<bool> deleteSavingsGoal(int id) async {
    try {
      int result = await DatabaseHelper.instance.deleteSavingsGoal(id);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // LOGIKA STATISTIK & ANALISIS
  // ==========================================

  Future<Map<String, double>> getMonthlySummary(int month, int year) async {
    List<Map<String, dynamic>> transactions = await getUserTransactions();
    double income = 0.0;
    double expense = 0.0;

    for (var trx in transactions) {
      try {
        DateTime date = DateTime.parse(trx['date']);
        if (date.month == month && date.year == year) {
          if (trx['type'] == 'income') {
            income += trx['amount'];
          } else {
            expense += trx['amount'];
          }
        }
      } catch (e) {
        continue;
      }
    }
    return {'income': income, 'expense': expense, 'net': income - expense};
  }

  Future<Map<String, double>> getExpensesByCategory(int month, int year) async {
    List<Map<String, dynamic>> transactions = await getUserTransactions();
    Map<String, double> categoryTotals = {};

    for (var trx in transactions) {
      try {
        DateTime date = DateTime.parse(trx['date']);
        if (date.month == month &&
            date.year == year &&
            trx['type'] == 'expense') {
          String category = trx['category'];
          double amount = trx['amount'];
          categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
        }
      } catch (e) {
        continue;
      }
    }
    return categoryTotals;
  }

  // [BARU] Mengambil ringkasan data untuk dikirim ke AI
  Future<String> getAIFinancialContext() async {
    double balance = await getTotalBalance();
    final summary = await getMonthlySummary(
      DateTime.now().month,
      DateTime.now().year,
    );
    final goals = await getUserSavingsGoals();
    final expenses = await getExpensesByCategory(
      DateTime.now().month,
      DateTime.now().year,
    );

    String context = "Saldo Utama: Rp ${balance.toStringAsFixed(0)}\n";
    context +=
        "Pemasukan Bulan Ini: Rp ${summary['income']?.toStringAsFixed(0)}\n";
    context +=
        "Pengeluaran Bulan Ini: Rp ${summary['expense']?.toStringAsFixed(0)}\n";

    context += "\nTarget Tabungan:\n";
    for (var g in goals) {
      context +=
          "- ${g['goal_name']}: ${g['current_amount']}/${g['target_amount']} (DL: ${g['deadline']})\n";
    }

    context += "\nDetail Pengeluaran Per Kategori:\n";
    expenses.forEach((key, value) {
      context += "- $key: Rp ${value.toStringAsFixed(0)}\n";
    });

    return context;
  }

  Future<String> getQuickAIInsight(String type) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) return "API Key tidak ditemukan.";

      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      // Ambil data untuk konteks
      double balance = await getTotalBalance();
      final goals = await getUserSavingsGoals();
      final summary = await getMonthlySummary(
        DateTime.now().month,
        DateTime.now().year,
      );

      String prompt = "";
      if (type == 'statistic') {
        prompt =
            "Berikan 1 kalimat saran keuangan singkat dan sangat spesifik (maksimal 20 kata) untuk user dengan data: "
            "Saldo Rp ${balance.toStringAsFixed(0)}, Pemasukan Rp ${summary['income']}, Pengeluaran Rp ${summary['expense']}. "
            "Gunakan bahasa Indonesia yang gaul dan tambahkan emoji.";
      } else {
        prompt =
            "Berikan 1 kalimat motivasi menabung singkat (maksimal 20 kata) berdasarkan data target ini: "
            "User punya ${goals.length} target. Berikan semangat agar target yang paling dekat deadline-nya segera tercapai. "
            "Gunakan bahasa Indonesia yang seru dan emoji.";
      }

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "Gagal mendapatkan insight.";
    } catch (e) {
      print("🚨 ERROR AI INSIGHT: $e");
      return "Artha AI Gagal mendapatkan insight.";
    }
  }

  // [DIPERBAIKI] Ditambah parameter bulan dan tahun
  Future<List<Map<String, dynamic>>> getTransactionsWithLocation(
      int month, int year) async {
    final db = await DatabaseHelper.instance.database;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? currentUserId = prefs.getInt('userId');

    if (currentUserId == null) return [];

    // Menggunakan parameter yang dikirim dari UI
    final String monthStr = month.toString().padLeft(2, '0');
    final String yearStr = year.toString();

    return await db.query(
      'transactions',
      where:
          "user_id = ? AND strftime('%m', date) = ? AND strftime('%Y', date) = ? AND latitude IS NOT NULL",
      whereArgs: [currentUserId, monthStr, yearStr],
    );
  }
}
