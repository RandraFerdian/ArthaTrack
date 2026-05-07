import 'package:arthatrack/controllers/finance_controller.dart';

class TargetController {
  final FinanceController _financeController = FinanceController();

  List<Map<String, dynamic>> goals = [];
  bool isLoading = true;
  String aiInsight =
      "Lihat apa kata Artha AI tentang progres dan target tabunganmu!";
  bool isFetchingAI = false;

  // Fungsi Inisialisasi
  Future<void> init(Function updateUI) async {
    await loadGoals(updateUI);
  }

  // Mengambil Data Target dari Database
  Future<void> loadGoals(Function updateUI) async {
    isLoading = true;
    updateUI();

    final rawGoals = await _financeController.getUserSavingsGoals();
    final sortedGoals = rawGoals.toList();

    // Logika Pengurutan: Yang belum tercapai & deadline terdekat di atas
    sortedGoals.sort((a, b) {
      bool aAchieved = a['current_amount'] >= a['target_amount'];
      bool bAchieved = b['current_amount'] >= b['target_amount'];
      if (aAchieved == bAchieved) {
        return DateTime.parse(a['deadline'])
            .compareTo(DateTime.parse(b['deadline']));
      }
      return aAchieved ? 1 : -1;
    });

    goals = sortedGoals;
    isLoading = false;
    updateUI();
  }

  // Memanggil Artha AI untuk Target
  Future<void> fetchAIInsight(Function updateUI) async {
    isFetchingAI = true;
    updateUI();

    final insight = await _financeController.getQuickAIInsight('target');

    aiInsight = insight;
    isFetchingAI = false;
    updateUI();
  }

  // Simpan / Update Target
  Future<void> saveGoal({
    int? existingId,
    required String name,
    required double amount,
    required String deadline,
  }) async {
    if (existingId == null) {
      await _financeController.addSavingsGoal(name, amount, deadline);
    } else {
      await _financeController.updateSavingsGoal(
          existingId, name, amount, deadline);
    }
  }

  // Tambah Saldo Tabungan
  Future<void> addMoneyToGoal(
      int goalId, double amount, String goalName) async {
    await _financeController.addMoneyToGoal(goalId, amount, goalName);
  }

  // Hapus Target
  Future<void> deleteGoal(int id) async {
    await _financeController.deleteSavingsGoal(id);
  }

  // --- Utility Functions ---

  String formatRupiah(double amount) {
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  int calculateDaysLeft(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime target = DateTime(deadline.year, deadline.month, deadline.day);
      return target.difference(today).inDays;
    } catch (e) {
      return 0;
    }
  }
}
