import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:arthatrack/src/core/app_colors.dart';
import 'package:arthatrack/src/core/app_font.dart';
import 'package:arthatrack/src/core/app_routes.dart';

// ==========================================
// 1. KARTU SUMMARY (Pemasukan / Pengeluaran)
// ==========================================
class SummaryCard extends StatelessWidget {
  final String title;
  final String formattedAmount;
  final Color color;
  final IconData icon;
  final String actionId;

  const SummaryCard({
    super.key,
    required this.title,
    required this.formattedAmount,
    required this.color,
    required this.icon,
    required this.actionId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.transactionHistory,
          arguments: {'initialFilter': actionId},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title,
                        style: AppFont.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(formattedAmount,
                  style:
                      AppFont.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. STATUS KEUANGAN (Sehat / Defisit)
// ==========================================
class FinancialStatus extends StatelessWidget {
  final double income;
  final double expense;

  const FinancialStatus(
      {super.key, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    if (income == 0 && expense == 0) return const SizedBox();
    bool isHealthy = income >= expense;
    Color statusColor = isHealthy ? AppColors.primary : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isHealthy
                  ? "Keuanganmu 30 hari terakhir stabil. Pertahankan!"
                  : "Awas! Pengeluaranmu 30 hari terakhir lebih besar dari pemasukan.",
              style: AppFont.bodyMedium
                  .copyWith(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. GRAFIK TREN HARIAN (Dinamic Date)
// ==========================================
class TrendChart extends StatelessWidget {
  final List<FlSpot> spots;
  final DateTime startDate;
  final String Function(double) formatRupiah;

  const TrendChart(
      {super.key,
      required this.spots,
      required this.startDate,
      required this.formatRupiah});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) return const SizedBox();
    const chartColor = Color(0xFF2962FF);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: chartColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.show_chart_rounded,
                    color: chartColor, size: 16),
              ),
              const SizedBox(width: 12),
              Text("Tren Saldo Harian", style: AppFont.h4),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white10,
                        strokeWidth: 1,
                        dashArray: [5, 5])),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 6, // Muncul setiap 6 hari agar tidak penuh
                      getTitlesWidget: (value, meta) {
                        // Konversi offset (0-30) menjadi tanggal nyata
                        DateTime actualDate =
                            startDate.add(Duration(days: value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("${actualDate.day}/${actualDate.month}",
                              style: AppFont.overline),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: chartColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [
                            chartColor.withOpacity(0.3),
                            chartColor.withOpacity(0.0)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppColors.surfaceVariant,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      DateTime actualDate =
                          startDate.add(Duration(days: spot.x.toInt()));
                      return LineTooltipItem(
                          "Tgl ${actualDate.day}/${actualDate.month}\n${formatRupiah(spot.y)}",
                          AppFont.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold));
                    }).toList(),
                  ),
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. KARTU INSIGHT AI
// ==========================================
class ArthaInsightCard extends StatelessWidget {
  final String insight;
  final bool isFetching;
  final VoidCallback onFetch;

  const ArthaInsightCard(
      {super.key,
      required this.insight,
      required this.isFetching,
      required this.onFetch});

  @override
  Widget build(BuildContext context) {
    const aiColor = Color(0xFF651FFF);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.surface,
          const Color(0xFF311B92).withOpacity(0.3)
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: aiColor.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
              color: aiColor.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFB388FF), size: 20),
              const SizedBox(width: 8),
              Text("Artha AI Insight",
                  style: AppFont.bodyMedium.copyWith(
                      color: const Color(0xFFB388FF),
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: aiColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text("BETA",
                    style: AppFont.overline
                        .copyWith(color: const Color(0xFFB388FF))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight,
              style: AppFont.bodyMedium
                  .copyWith(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: isFetching ? null : onFetch,
              style: ElevatedButton.styleFrom(
                  backgroundColor: aiColor.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              icon: isFetching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.textPrimary, strokeWidth: 2))
                  : const Icon(Icons.psychology_rounded,
                      color: AppColors.textPrimary, size: 18),
              label: Text(isFetching ? "Menganalisis..." : "✨ Dapatkan Insight",
                  style:
                      AppFont.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. LEGEND DONUT CHART
// ==========================================
class LegendItem extends StatelessWidget {
  final int index;
  final int touchedIndex;
  final String category;
  final double amount;
  final Color color;
  final String formattedAmount;
  final VoidCallback onTap;

  const LegendItem(
      {super.key,
      required this.index,
      required this.touchedIndex,
      required this.category,
      required this.amount,
      required this.color,
      required this.formattedAmount,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isTouched = index == touchedIndex;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isTouched ? 10 : 6),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: isTouched ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
                width: 14,
                height: 14,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(category,
                    style: AppFont.bodyMedium.copyWith(
                        color: isTouched ? color : AppColors.textPrimary,
                        fontWeight:
                            isTouched ? FontWeight.bold : FontWeight.normal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Flexible(
                child: Text(formattedAmount,
                    style: AppFont.bodyMedium.copyWith(
                        color: isTouched ? color : AppColors.textSecondary,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
