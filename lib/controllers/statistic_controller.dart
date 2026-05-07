// Lokasi: lib/controllers/statistic_controller.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:arthatrack/controllers/finance_controller.dart';

class StatisticController {
  final FinanceController _financeController = FinanceController();

  bool isLoading = true;

  // --- Data Per Bulan Kalender (Untuk Summary Card & Pie Chart) ---
  DateTime currentDate = DateTime.now();
  double income = 0.0;
  double expense = 0.0;
  double net = 0.0;
  double monthlyExpense = 0.0;
  List<MapEntry<String, double>> categoryDataList = [];

  // --- Data 30 Hari Terakhir (Hanya Untuk Grafik Tren Garis) ---
  List<FlSpot> chartSpots = [];
  late DateTime chartStartDate;

  int touchedIndex = -1;
  String aiInsight = "Tekan tombol di bawah untuk mendapatkan analisis pintar!";
  bool isFetchingAI = false;
  DateTime lastRefreshTime = DateTime.now();

  Future<void> loadStatisticData([Function? updateUI]) async {
    isLoading = true;
    updateUI?.call();

    List<Map<String, dynamic>> allTrx =
        await _financeController.getUserTransactions();

    // ========================================================
    // PERSIAPAN RENTANG WAKTU
    // ========================================================
    DateTime now = DateTime.now();

    // Rentang untuk Tren (Paten 30 Hari Kebelakang)
    chartStartDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 30));
    DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Rentang untuk Summary Card (Berdasarkan Bulan yang Dipilih)
    DateTime startOfMonth = DateTime(currentDate.year, currentDate.month, 1);
    // Mengambil hari terakhir di bulan tersebut
    DateTime endOfMonth =
        DateTime(currentDate.year, currentDate.month + 1, 0, 23, 59, 59);

    double tempIncome = 0.0;
    double tempExpense = 0.0;
    double previousBalance = 0.0;
    Map<int, double> dailyNet = {for (var i = 0; i <= 30; i++) i: 0.0};

    // ========================================================
    // 1. LOOPING TRANSAKSI (Filter Data)
    // ========================================================
    for (var trx in allTrx) {
      try {
        DateTime date = DateTime.parse(trx['date']);
        double amount = trx['amount'] ?? 0.0;
        bool isIncome = trx['type'] == 'income';

        // --- A. Hitung Untuk Summary Card (Bulan Ini) ---
        if (date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
          if (isIncome) {
            tempIncome += amount;
          } else {
            tempExpense += amount;
          }
        }

        // --- B. Hitung Untuk Grafik Tren (30 Hari Terakhir) ---
        if (date.isBefore(chartStartDate)) {
          previousBalance += isIncome ? amount : -amount;
        } else if (date
                .isAfter(chartStartDate.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endOfToday.add(const Duration(seconds: 1)))) {
          int dayOffset = date.difference(chartStartDate).inDays;
          if (dayOffset >= 0 && dayOffset <= 30) {
            dailyNet[dayOffset] =
                dailyNet[dayOffset]! + (isIncome ? amount : -amount);
          }
        }
      } catch (e) {}
    }

    // Assign hasil Summary ke variabel utama
    income = tempIncome;
    expense = tempExpense;
    net = tempIncome - tempExpense;

    // Build Grafik Garis
    List<FlSpot> spots = [];
    double runningTotal = previousBalance;
    for (int i = 0; i <= 30; i++) {
      runningTotal += dailyNet[i]!;
      spots.add(FlSpot(i.toDouble(), runningTotal));
    }
    chartSpots = spots;

    // ========================================================
    // 2. HITUNG DATA PER BULAN TERPILIH (Pie Chart Distribusi)
    // ========================================================
    final categoryData = await _financeController.getExpensesByCategory(
      currentDate.month,
      currentDate.year,
    );

    double tempMonthlyExpense = 0.0;
    categoryData.forEach((key, value) => tempMonthlyExpense += value);
    monthlyExpense = tempMonthlyExpense;

    categoryDataList = categoryData.entries.toList();
    categoryDataList.sort((a, b) => b.value.compareTo(a.value));

    isLoading = false;
    touchedIndex = -1;
    updateUI?.call();
  }

  Future<void> fetchAIInsight([Function? updateUI]) async {
    isFetchingAI = true;
    updateUI?.call();
    final insight = await _financeController.getQuickAIInsight('statistic');
    aiInsight = insight;
    isFetchingAI = false;
    updateUI?.call();
  }

  void changeMonth(int delta, Function updateUI) {
    currentDate = DateTime(currentDate.year, currentDate.month + delta, 1);
    loadStatisticData(updateUI);
  }

  void setTouchedIndex(int index, Function updateUI) {
    touchedIndex = index;
    updateUI();
  }

  String formatRupiah(double amount) {
    String prefix = amount < 0 ? "- " : "";
    String amountStr = amount.abs().toStringAsFixed(0);
    String formatted = amountStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return "$prefix Rp $formatted";
  }
}
