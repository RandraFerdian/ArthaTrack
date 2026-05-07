// Lokasi: lib/screens/transaction/transaction_history_widget.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arthatrack/src/core/app_colors.dart';
import 'package:arthatrack/src/core/app_font.dart';

// ==========================================
// 1. WIDGET: TAB FILTER TIPE (Semua, Pemasukan, Pengeluaran)
// ==========================================
class TypeFilterTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const TypeFilterTab(
      {super.key,
      required this.title,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppFont.bodySmall.copyWith(
              color:
                  isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. WIDGET: CHIP FILTER BULAN
// ==========================================
class MonthFilterChip extends StatelessWidget {
  final String month;
  final bool isSelected;
  final VoidCallback onTap;

  const MonthFilterChip(
      {super.key,
      required this.month,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white24),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          month,
          style: AppFont.bodySmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. WIDGET: KARTU SUMMARY TOTAL
// ==========================================
class SummaryTotalCard extends StatelessWidget {
  final String formattedIncome;
  final String formattedExpense;

  const SummaryTotalCard(
      {super.key,
      required this.formattedIncome,
      required this.formattedExpense});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Pemasukan", style: AppFont.caption),
                const SizedBox(height: 4),
                Text("+ $formattedIncome",
                    style: AppFont.bodyMedium.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Total Pengeluaran", style: AppFont.caption),
                const SizedBox(height: 4),
                Text("- $formattedExpense",
                    style: AppFont.bodyMedium.copyWith(
                        color: AppColors.error, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. WIDGET: KARTU ITEM TRANSAKSI
// ==========================================
class TransactionItemCard extends StatelessWidget {
  final Map<String, dynamic> trx;
  final String amountText;
  final VoidCallback onTap;

  const TransactionItemCard(
      {super.key,
      required this.trx,
      required this.amountText,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isIncome = trx['type'] == 'income';
    Color iconColor = isIncome ? AppColors.primary : AppColors.error;

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.15),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trx['title'],
                        style: AppFont.bodySmall
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(trx['category'], style: AppFont.caption),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  "${isIncome ? '+' : '-'} $amountText",
                  style: AppFont.bodySmall
                      .copyWith(color: iconColor, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. HELPER: MUNCULKAN BOTTOM SHEET DETAIL
// ==========================================
class TransactionHistoryWidgets {
  static void showTransactionDetail(
    BuildContext context,
    Map<String, dynamic> trx,
    String displayAmount,
    VoidCallback onDelete,
    VoidCallback onEdit,
  ) {
    bool isIncome = trx['type'] == 'income';
    bool hasLocation = trx['latitude'] != null && trx['longitude'] != null;
    Color iconColor = isIncome ? AppColors.primary : AppColors.error;

    String formattedDate = trx['date'];
    try {
      DateTime date = DateTime.parse(trx['date']);
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
        'Des'
      ];
      formattedDate =
          "${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: iconColor,
                    size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                "${isIncome ? '+' : '-'} $displayAmount",
                style: AppFont.h1.copyWith(color: iconColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(trx['title'],
                  style: AppFont.h4, textAlign: TextAlign.center),
              const SizedBox(height: 40),
              _buildDetailRow(
                  Icons.category_rounded, "Kategori", trx['category']),
              _buildDetailRow(
                  Icons.calendar_today_rounded, "Tanggal", formattedDate),
              _buildDetailRow(
                Icons.location_on_rounded,
                "Lokasi (GPS)",
                hasLocation
                    ? "${trx['latitude']}, ${trx['longitude']}"
                    : "Lokasi tidak tercatat",
                isLink: hasLocation,
                onTap: hasLocation
                    ? () async {
                        final Uri url = Uri.parse(
                            "http://googleusercontent.com/maps.google.com/maps?q=${trx['latitude']},${trx['longitude']}");
                        if (await canLaunchUrl(url))
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                      }
                    : null,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      label: Text("Hapus",
                          style: AppFont.bodyMedium
                              .copyWith(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.textPrimary),
                      label: Text("Edit",
                          style: AppFont.bodyMedium
                              .copyWith(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text("Tutup",
                      style: AppFont.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildDetailRow(IconData icon, String label, String value,
      {bool isLink = false, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 4, left: 4, right: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppFont.caption),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppFont.bodyMedium.copyWith(
                        color:
                            isLink ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        decoration: isLink
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
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
