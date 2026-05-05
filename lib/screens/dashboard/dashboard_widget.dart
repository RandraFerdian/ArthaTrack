import 'package:flutter/material.dart';
import 'package:arthatrack/src/core/app_colors.dart';
import 'package:arthatrack/src/core/app_font.dart';

// ==========================================
// 1. KARTU SALDO UTAMA
// ==========================================
class BalanceCard extends StatelessWidget {
  final String selectedCurrency;
  final bool isConverting;
  final String formattedBalance;
  final VoidCallback onTap;

  const BalanceCard({
    super.key,
    required this.selectedCurrency,
    required this.isConverting,
    required this.formattedBalance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            // Memanfaatkan AppColors.secondary dipadu warna biru gelap
            colors: [AppColors.secondary, Color(0xFF0D47A1)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Saldo",
                    style: AppFont.bodyLarge.copyWith(color: Colors.white70)),
                Text(selectedCurrency,
                    style: AppFont.bodyLarge
                        .copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            isConverting
                ? const CircularProgressIndicator(color: AppColors.textPrimary)
                : Text(
                    formattedBalance,
                    style: AppFont.h1, // Menggunakan Heading 1 dari AppFont
                  ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. TOMBOL MENU CEPAT (ACTION BUTTON)
// ==========================================
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: AppColors.surface, // Menggunakan warna surface
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppFont.overline, // Menggunakan gaya tulisan Overline
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. KARTU RIWAYAT TRANSAKSI TERBARU
// ==========================================
class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> trx;
  final String amountStr;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.trx,
    required this.amountStr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isIncome = trx['type'] == 'income';
    Color trxColor = isIncome ? AppColors.primary : AppColors.error;

    return Card(
      color: AppColors.surface, // Menggunakan warna surface
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: trxColor.withOpacity(0.2),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: trxColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trx['title'],
                      style: AppFont.bodySmall
                          .copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      trx['category'],
                      style: AppFont.caption, // Menggunakan gaya caption
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  "${isIncome ? '+' : '-'} $amountStr",
                  style: AppFont.bodySmall
                      .copyWith(color: trxColor, fontWeight: FontWeight.bold),
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
// 4. BARIS DETAIL UNTUK MODAL BOTTOM SHEET
// ==========================================
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.surfaceVariant, // Warna surface Variant
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
