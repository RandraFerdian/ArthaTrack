import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
import 'package:arthatrack/controllers/currency_controller.dart';
import 'package:arthatrack/src/core/app_routes.dart';
import 'package:arthatrack/src/core/session_manager.dart';

class DashboardController {
  final FinanceController _financeController = FinanceController();
  final CurrencyController _currencyController = CurrencyController();

  double totalBalance = 0.0;
  double displayBalance = 0.0;
  List<Map<String, dynamic>> recentTransactions = [];
  String selectedCurrency = 'IDR';
  bool isLoading = true;
  bool isConverting = false;
  String userName = "User";

  DateTime lastRefreshTime = DateTime.now();

  void init() {
    // Initialization logic if needed
  }

  Future<void> loadDashboardData([Function? updateUI]) async {
    isLoading = true;
    updateUI?.call();

    // Load balance
    final balance = await _financeController.getTotalBalance();
    totalBalance = balance;
    displayBalance = balance;
    selectedCurrency = 'IDR';
    recentTransactions = await _financeController.getUserTransactions(limit: 5);
    userName = SessionManager.username ?? "User";

    isLoading = false;
    updateUI?.call();
  }

  Future<void> navigateToFeature(BuildContext context, String actionId) async {
    if (actionId == "income" || actionId == "expense") {
      final shouldRefresh = await Navigator.pushNamed(
        context,
        AppRoutes.addTransaction,
        arguments: {'initialType': actionId},
      );
      if (shouldRefresh == true) {
        await loadDashboardData();
      }
    } else if (actionId == "conversion") {
      Navigator.pushNamed(context, AppRoutes.currencyConversion);
    } else if (actionId == "target") {
      Navigator.pushNamed(context, AppRoutes.target);
    } else if (actionId == "game") {
      Navigator.pushNamed(context, AppRoutes.minigame);
    } else if (actionId == "time_conversion") {
      Navigator.pushNamed(context, AppRoutes.timezone);
    } else if (actionId == "chat_ai") {
      Navigator.pushNamed(context, AppRoutes.chat);
    } else if (actionId == "maps") {
      Navigator.pushNamed(context, AppRoutes.maps);
    } else if (actionId == "history") {
      Navigator.pushNamed(context, AppRoutes.transactionHistory)
          .then((_) => loadDashboardData());
    }
  }

  Future<void> changeDisplayCurrency(String code, Function updateUI) async {
    if (code == 'IDR') {
      displayBalance = totalBalance;
      selectedCurrency = 'IDR';
      updateUI();
      return;
    }
    isConverting = true;
    updateUI();
    double? result = await _currencyController.convertCurrency(
      fromCurrency: 'IDR',
      toCurrency: code,
      amount: totalBalance,
    );
    isConverting = false;
    if (result != null) {
      displayBalance = result;
      selectedCurrency = code;
    }
    updateUI();
  }

  Future<void> deleteTransaction(int id) async {
    await _financeController.deleteTransaction(id);
  }

  String formatCurrency(double amount, String code) {
    String formatted = amount.toStringAsFixed(2);
    List<String> parts = formatted.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add commas for thousands
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formattedInteger =
        integerPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    String finalAmount =
        parts.length > 1 ? "$formattedInteger.$decimalPart" : formattedInteger;
    if (code == 'IDR') return "Rp $finalAmount";
    return "$code $finalAmount";
  }
}
