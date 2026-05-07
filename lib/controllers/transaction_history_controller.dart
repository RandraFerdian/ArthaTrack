// Lokasi: lib/controllers/transaction_history_controller.dart

import 'package:arthatrack/controllers/finance_controller.dart';

class TransactionHistoryController {
  final FinanceController _financeController = FinanceController();

  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  bool isLoading = true;

  String selectedTypeFilter = 'all';
  String selectedMonth = "Semua";
  List<String> availableMonths = ["Semua"];

  double currentIncome = 0.0;
  double currentExpense = 0.0;

  // Inisialisasi
  Future<void> init(String? initialFilter, Function updateUI) async {
    if (initialFilter != null) {
      selectedTypeFilter = initialFilter;
    }
    await loadHistory(updateUI);
  }

  // Ambil Data
  Future<void> loadHistory(Function updateUI) async {
    isLoading = true;
    updateUI();

    List<Map<String, dynamic>> transactions =
        await _financeController.getUserTransactions();

    Set<String> monthsSet = {"Semua"};
    for (var trx in transactions) {
      try {
        DateTime date = DateTime.parse(trx['date']);
        List<String> monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Ags',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ];
        monthsSet.add("${monthNames[date.month - 1]} ${date.year}");
      } catch (e) {}
    }

    allTransactions = transactions;
    availableMonths = monthsSet.toList();
    isLoading = false;

    applyFilters(updateUI);
  }

  // Terapkan Filter
  void applyFilters(Function updateUI) {
    filteredTransactions = allTransactions.where((trx) {
      if (selectedTypeFilter != 'all' && trx['type'] != selectedTypeFilter) {
        return false;
      }
      if (selectedMonth != "Semua") {
        try {
          DateTime date = DateTime.parse(trx['date']);
          List<String> monthNames = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'Mei',
            'Jun',
            'Jul',
            'Ags',
            'Sep',
            'Okt',
            'Nov',
            'Des',
          ];
          String trxMonth = "${monthNames[date.month - 1]} ${date.year}";
          if (trxMonth != selectedMonth) return false;
        } catch (e) {
          return false;
        }
      }
      return true;
    }).toList();

    _calculateTotals();
    updateUI();
  }

  void _calculateTotals() {
    currentIncome = 0;
    currentExpense = 0;
    for (var trx in filteredTransactions) {
      if (trx['type'] == 'income') {
        currentIncome += trx['amount'];
      } else {
        currentExpense += trx['amount'];
      }
    }
  }

  // Setters
  void setTypeFilter(String type, Function updateUI) {
    selectedTypeFilter = type;
    applyFilters(updateUI);
  }

  void setMonthFilter(String month, Function updateUI) {
    selectedMonth = month;
    applyFilters(updateUI);
  }

  // Hapus Data
  Future<void> deleteTransaction(int id, Function updateUI) async {
    await _financeController.deleteTransaction(id);
    await loadHistory(updateUI);
  }

  // Helpers
  String formatRupiah(double amount) {
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  String getDateHeader(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        return "Hari Ini";
      }
      if (date.day == now.day - 1 &&
          date.month == now.month &&
          date.year == now.year) {
        return "Kemarin";
      }

      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return "Tanggal Tidak Diketahui";
    }
  }
}
