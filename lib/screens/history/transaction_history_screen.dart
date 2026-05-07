// Lokasi: lib/screens/transaction/transaction_history_screen.dart

import 'package:flutter/material.dart';
import 'package:arthatrack/controllers/transaction_history_controller.dart';
import 'package:arthatrack/screens/history/transaction_history_widget.dart';
import 'package:arthatrack/screens/transaction/add_transaction_screen.dart';
import 'package:arthatrack/src/core/app_colors.dart';
import 'package:arthatrack/src/core/app_font.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String? initialFilter;
  const TransactionHistoryScreen({super.key, this.initialFilter});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late TransactionHistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TransactionHistoryController();
    _controller.init(widget.initialFilter, () => setState(() {}));
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("Hapus Transaksi?", style: AppFont.h4),
        content: Text("Data yang dihapus tidak bisa dikembalikan.",
            style: AppFont.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal",
                style: AppFont.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog
              await _controller.deleteTransaction(id, () => setState(() {}));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Transaksi dihapus",
                      style: AppFont.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text("Hapus",
                style: AppFont.bodyMedium.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Riwayat Transaksi", style: AppFont.h4),
        centerTitle: true,
      ),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // 1. FILTER TIPE
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(25)),
                    child: Row(
                      children: [
                        TypeFilterTab(
                            title: 'Semua',
                            isSelected: _controller.selectedTypeFilter == 'all',
                            onTap: () => _controller.setTypeFilter(
                                'all', () => setState(() {}))),
                        TypeFilterTab(
                            title: 'Pemasukan',
                            isSelected:
                                _controller.selectedTypeFilter == 'income',
                            onTap: () => _controller.setTypeFilter(
                                'income', () => setState(() {}))),
                        TypeFilterTab(
                            title: 'Pengeluaran',
                            isSelected:
                                _controller.selectedTypeFilter == 'expense',
                            onTap: () => _controller.setTypeFilter(
                                'expense', () => setState(() {}))),
                      ],
                    ),
                  ),
                ),

                // 2. FILTER BULAN
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _controller.availableMonths.length,
                    itemBuilder: (context, index) {
                      String month = _controller.availableMonths[index];
                      return MonthFilterChip(
                        month: month,
                        isSelected: _controller.selectedMonth == month,
                        onTap: () => _controller.setMonthFilter(
                            month, () => setState(() {})),
                      );
                    },
                  ),
                ),

                // 3. KARTU SUMMARY TOTAL
                if (_controller.filteredTransactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SummaryTotalCard(
                      formattedIncome:
                          _controller.formatRupiah(_controller.currentIncome),
                      formattedExpense:
                          _controller.formatRupiah(_controller.currentExpense),
                    ),
                  ),

                // 4. DAFTAR TRANSAKSI
                Expanded(
                  child: _controller.filteredTransactions.isEmpty
                      ? Center(
                          child: Text("Tidak ada transaksi.",
                              style: AppFont.subtitle))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _controller.filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final trx = _controller.filteredTransactions[index];
                            String amountText =
                                _controller.formatRupiah(trx['amount']);

                            // Logika Header Tanggal
                            final String currentHeader =
                                _controller.getDateHeader(trx['date']);
                            final String? prevHeader = index > 0
                                ? _controller.getDateHeader(_controller
                                    .filteredTransactions[index - 1]['date'])
                                : null;
                            bool isNewDay = currentHeader != prevHeader;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isNewDay)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 16, bottom: 8, left: 4),
                                    child: Text(currentHeader,
                                        style: AppFont.caption.copyWith(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                TransactionItemCard(
                                  trx: trx,
                                  amountText: amountText,
                                  onTap: () => TransactionHistoryWidgets
                                      .showTransactionDetail(
                                    context, trx, amountText,
                                    () => _confirmDelete(
                                        trx['id']), // Action Delete
                                    () => Navigator.push(
                                      // Action Edit
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              AddTransactionScreen(
                                                  initialType: trx['type'],
                                                  existingTransaction: trx)),
                                    ).then((_) => _controller
                                        .loadHistory(() => setState(() {}))),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
