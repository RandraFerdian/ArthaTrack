import 'package:flutter/material.dart';
import 'package:arthatrack/src/core/app_colors.dart';
import 'package:arthatrack/src/core/app_font.dart';

// ==========================================
// WIDGET: KARTU TARGET TABUNGAN
// ==========================================
class TargetGoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final double target;
  final double current;
  final double progress;
  final bool isAchieved;
  final int daysLeft;
  final String formattedCurrent;
  final String formattedTarget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddMoney;

  const TargetGoalCard({
    super.key,
    required this.goal,
    required this.target,
    required this.current,
    required this.progress,
    required this.isAchieved,
    required this.daysLeft,
    required this.formattedCurrent,
    required this.formattedTarget,
    required this.onEdit,
    required this.onDelete,
    required this.onAddMoney,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface, // Menggunakan warna surface dari tema
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    // Menggunakan AppColors.primary (hijau) untuk sukses
                    color: isAchieved
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.secondary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAchieved
                        ? Icons.emoji_events_rounded
                        : Icons.flag_rounded,
                    color: isAchieved ? AppColors.primary : AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal['goal_name'],
                        style: AppFont.bodyLarge
                            .copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAchieved
                            ? "Target Tercapai! 🎉"
                            : (daysLeft < 0
                                ? "Terlambat ${daysLeft.abs()} hari"
                                : "Sisa $daysLeft hari"),
                        style: AppFont.caption.copyWith(
                          color: isAchieved
                              ? AppColors.primary
                              : (daysLeft <= 7
                                  ? AppColors.error
                                  : AppColors.textSecondary),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.surfaceVariant,
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textSecondary),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit,
                            color: AppColors.textPrimary, size: 18),
                        const SizedBox(width: 8),
                        Text("Edit", style: AppFont.bodyMedium)
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Text("Hapus",
                            style: AppFont.bodyMedium
                                .copyWith(color: AppColors.error))
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedCurrent,
                  style: AppFont.bodyMedium.copyWith(
                    color:
                        isAchieved ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("dari $formattedTarget", style: AppFont.caption),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAchieved ? AppColors.primary : AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!isAchieved)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: onAddMoney,
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.textPrimary, size: 18),
                  label: Text("Nabung",
                      style: AppFont.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET: KARTU INSIGHT AI
// ==========================================
class TargetAIInsightCard extends StatelessWidget {
  final String insight;
  final bool isFetching;
  final VoidCallback onFetch;

  const TargetAIInsightCard({
    super.key,
    required this.insight,
    required this.isFetching,
    required this.onFetch,
  });

  @override
  Widget build(BuildContext context) {
    const aiColor = Color(0xFF651FFF);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, const Color(0xFF311B92).withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
              Text(
                "Artha AI Target Insight",
                style: AppFont.bodyMedium.copyWith(
                    color: const Color(0xFFB388FF),
                    fontWeight: FontWeight.bold),
              ),
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
              style: AppFont.bodySmall
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
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: isFetching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.lightbulb_outline_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                isFetching ? "Menganalisis..." : "✨ Dapatkan Motivasi AI",
                style: AppFont.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
