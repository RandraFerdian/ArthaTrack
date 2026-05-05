import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:arthatrack/controllers/finance_controller.dart';

class StatisticController {
  final FinanceController _financeController = FinanceController();

  bool isLoading = true;

  // --- Data 30 Hari Terakhir (Untuk Kartu & Grafik Garis) ---
  double income = 0.0;
  double expense = 0.0;
  double net = 0.0;
  List<FlSpot> chartSpots = [];
  late DateTime chartStartDate;

  // --- Data Per Bulan Kalender (Untuk Pie Chart) ---
  DateTime currentDate = DateTime.now();
  double monthlyExpense = 0.0; // Total pengeluaran khusus di bulan terpilih
  List<MapEntry<String, double>> categoryDataList = [];

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
    // 1. HITUNG DATA 30 HARI TERAKHIR (Summary & Line Chart)
    // ========================================================
    DateTime now = DateTime.now();
    chartStartDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 30));
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    double tempIncome = 0.0;
    double tempExpense = 0.0;
    double previousBalance = 0.0;
    Map<int, double> dailyNet = {for (var i = 0; i <= 30; i++) i: 0.0};

    for (var trx in allTrx) {
      try {
        DateTime date = DateTime.parse(trx['date']);
        double amount = trx['amount'] ?? 0.0;
        bool isIncome = trx['type'] == 'income';

        if (date.isBefore(chartStartDate)) {
          previousBalance += isIncome ? amount : -amount;
        } else if (date
                .isAfter(chartStartDate.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endOfDay.add(const Duration(seconds: 1)))) {
          if (isIncome) {
            tempIncome += amount;
          } else {
            tempExpense += amount;
          }
          int dayOffset = date.difference(chartStartDate).inDays;
          if (dayOffset >= 0 && dayOffset <= 30) {
            dailyNet[dayOffset] =
                dailyNet[dayOffset]! + (isIncome ? amount : -amount);
          }
        }
      } catch (e) {}
    }

    List<FlSpot> spots = [];
    double runningTotal = previousBalance;
    for (int i = 0; i <= 30; i++) {
      runningTotal += dailyNet[i]!;
      spots.add(FlSpot(i.toDouble(), runningTotal));
    }

    income = tempIncome;
    expense = tempExpense;
    net = tempIncome - tempExpense;
    chartSpots = spots;

    // ========================================================
    // 2. HITUNG DATA PER BULAN TERPILIH (Pie Chart Distribusi)
    // ========================================================
    final categoryData = await _financeController.getExpensesByCategory(
      currentDate.month,
      currentDate.year,
    );

    // Hitung total pengeluaran bulan ini saja untuk referensi persentase
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
