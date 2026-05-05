import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:async';

import 'package:arthatrack/src/core/session_manager.dart';
import 'package:arthatrack/src/core/app_colors.dart';
import 'package:arthatrack/src/core/app_font.dart';
import 'package:arthatrack/controllers/statistic_controller.dart';
import 'package:arthatrack/screens/statistic/statistic_widget.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  late StatisticController _controller;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;

  final Map<String, Color> _categoryColors = {
    'Makanan': Colors.orangeAccent,
    'Transport': Colors.blueAccent,
    'Belanja': Colors.pinkAccent,
    'Hiburan': Colors.purpleAccent,
    'Tagihan': Colors.redAccent,
    'Kesehatan': Colors.tealAccent,
    'Investasi': AppColors.primary,
    'Lainnya': AppColors.textSecondary,
  };

  @override
  void initState() {
    super.initState();
    _controller = StatisticController();
    _controller.loadStatisticData(() => setState(() {}));
    _initAccelerometer();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _initAccelerometer() {
    _accelerometerSubscription = userAccelerometerEventStream()
        .listen((UserAccelerometerEvent event) async {
      if (!SessionManager.accelEnabled) return;
      double acceleration =
          sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

      if (acceleration > 15) {
        final now = DateTime.now();
        if (now.difference(_controller.lastRefreshTime).inSeconds > 3) {
          _controller.lastRefreshTime = now;
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                content: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF3949AB).withOpacity(0.5),
                          width: 1.5)),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded,
                          color: Color(0xFF8C9EFF), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Sinkronisasi Selesai",
                                style: AppFont.bodyMedium
                                    .copyWith(fontWeight: FontWeight.bold)),
                            Text("Data saldo & transaksi diperbarui",
                                style: AppFont.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          _controller.loadStatisticData(() => setState(() {}));
        }
      }
    });
  }

  List<PieChartSectionData> _buildDonutChartSections() {
    // Menggunakan monthlyExpense untuk persentase di Pie Chart
    if (_controller.monthlyExpense == 0) return [];

    return _controller.categoryDataList.asMap().entries.map((entry) {
      final int index = entry.key;
      final String category = entry.value.key;
      final double amount = entry.value.value;
      final bool isTouched = index == _controller.touchedIndex;
      final double percentage = (amount / _controller.monthlyExpense) * 100;
      final Color color = _categoryColors[category] ?? Colors.grey;

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: isTouched ? 55.0 : 45.0,
        titleStyle: AppFont.overline.copyWith(
            fontSize: isTouched ? 14.0 : 10.0, color: AppColors.textPrimary),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
      'Des'
    ];
    String currentMonthName =
        "${monthNames[_controller.currentDate.month - 1]} ${_controller.currentDate.year}";
    bool isCurrentMonth =
        _controller.currentDate.month == DateTime.now().month &&
            _controller.currentDate.year == DateTime.now().year;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Statistik Keuangan", style: AppFont.h4),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded,
                color: AppColors.textPrimary),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Fitur Export Laporan PDF segera hadir!"))),
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async =>
                  _controller.loadStatisticData(() => setState(() {})),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LABEL 30 HARI TERAKHIR (Untuk Kartu atas)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_rounded,
                                color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                                child: Text("30 Hari Terakhir",
                                    style: AppFont.bodyMedium
                                        .copyWith(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SUMMARY CARDS (30 HARI)
                    Row(
                      children: [
                        Expanded(
                            child: SummaryCard(
                                title: "Pemasukan",
                                formattedAmount: _controller
                                    .formatRupiah(_controller.income),
                                color: AppColors.primary,
                                icon: Icons.arrow_downward_rounded,
                                actionId: "income")),
                        const SizedBox(width: 16),
                        Expanded(
                            child: SummaryCard(
                                title: "Pengeluaran",
                                formattedAmount: _controller
                                    .formatRupiah(_controller.expense),
                                color: AppColors.error,
                                icon: Icons.arrow_upward_rounded,
                                actionId: "expense")),
                      ],
                    ),

                    // STATUS & TREND (30 HARI)
                    FinancialStatus(
                        income: _controller.income,
                        expense: _controller.expense),
                    const SizedBox(height: 32),
                    TrendChart(
                        spots: _controller.chartSpots,
                        startDate: _controller.chartStartDate,
                        formatRupiah: _controller.formatRupiah),
                    const SizedBox(height: 32),

                    // AI INSIGHT
                    ArthaInsightCard(
                        insight: _controller.aiInsight,
                        isFetching: _controller.isFetchingAI,
                        onFetch: () =>
                            _controller.fetchAIInsight(() => setState(() {}))),
                    const SizedBox(height: 32),

                    // DISTRIBUSI PENGELUARAN (PIE CHART - PER BULAN)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Distribusi", style: AppFont.h4),

                        // KONTROL BULAN PINDAH KE SINI
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded,
                                    color: AppColors.textPrimary, size: 20),
                                onPressed: () => _controller.changeMonth(
                                    -1, () => setState(() {})),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                              Text(currentMonthName,
                                  style: AppFont.bodySmall
                                      .copyWith(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: Icon(Icons.chevron_right_rounded,
                                    color: isCurrentMonth
                                        ? Colors.white24
                                        : AppColors.textPrimary,
                                    size: 20),
                                onPressed: isCurrentMonth
                                    ? null
                                    : () => _controller.changeMonth(
                                        1, () => setState(() {})),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    _controller.categoryDataList.isEmpty
                        ? Container(
                            height: 200,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24)),
                            child: Text("Belum ada pengeluaran di bulan ini.",
                                style: AppFont.subtitle))
                        : Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24)),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 220,
                                  child: PieChart(
                                    PieChartData(
                                      pieTouchData: PieTouchData(
                                        touchCallback: (FlTouchEvent event,
                                            pieTouchResponse) {
                                          if (!event
                                                  .isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection ==
                                                  null) {
                                            _controller.setTouchedIndex(
                                                -1, () => setState(() {}));
                                            return;
                                          }
                                          _controller.setTouchedIndex(
                                              pieTouchResponse.touchedSection!
                                                  .touchedSectionIndex,
                                              () => setState(() {}));
                                        },
                                      ),
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 50,
                                      sections: _buildDonutChartSections(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // INFO KATEGORI DIPILIH (Menggunakan monthlyExpense)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: _controller.touchedIndex == -1
                                            ? Colors.transparent
                                            : _categoryColors[_controller
                                                    .categoryDataList[
                                                        _controller
                                                            .touchedIndex]
                                                    .key]!
                                                .withOpacity(0.5),
                                        width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                          _controller.touchedIndex == -1
                                              ? "Total Pengeluaran Bulan Ini"
                                              : "Pengeluaran ${_controller.categoryDataList[_controller.touchedIndex].key}",
                                          style: AppFont.bodySmall.copyWith(
                                              color: _controller.touchedIndex ==
                                                      -1
                                                  ? AppColors.textSecondary
                                                  : _categoryColors[_controller
                                                      .categoryDataList[
                                                          _controller
                                                              .touchedIndex]
                                                      .key],
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(
                                          _controller.formatRupiah(
                                              _controller.touchedIndex == -1
                                                  ? _controller.monthlyExpense
                                                  : _controller
                                                      .categoryDataList[
                                                          _controller
                                                              .touchedIndex]
                                                      .value),
                                          style: AppFont.h2),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // DAFTAR LEGEND
                                ..._controller.categoryDataList
                                    .asMap()
                                    .entries
                                    .map((entry) => LegendItem(
                                          index: entry.key,
                                          touchedIndex:
                                              _controller.touchedIndex,
                                          category: entry.value.key,
                                          amount: entry.value.value,
                                          color: _categoryColors[
                                                  entry.value.key] ??
                                              Colors.grey,
                                          formattedAmount: _controller
                                              .formatRupiah(entry.value.value),
                                          onTap: () =>
                                              _controller.setTouchedIndex(
                                                  _controller.touchedIndex ==
                                                          entry.key
                                                      ? -1
                                                      : entry.key,
                                                  () => setState(() {})),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
