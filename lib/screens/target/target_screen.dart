import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arthatrack/controllers/target_controller.dart';
import 'package:arthatrack/screens/transaction/add_transaction_screen.dart';
import 'package:arthatrack/src/core/app_colors.dart';
import 'package:arthatrack/src/core/app_font.dart';
import 'package:arthatrack/screens/target/target_widget.dart'; // Import widget baru

class TargetScreen extends StatefulWidget {
  final bool isFromNavbar;

  const TargetScreen({super.key, this.isFromNavbar = false});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  late TargetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TargetController();
    _controller.init(() => setState(() {}));
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppFont.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showErrorDialog(String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text("Peringatan",
                style: AppFont.h4), // Menggunakan AppFont yang ada
          ],
        ),
        content: Text(message,
            style: AppFont.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("OK Mengerti",
                style: AppFont.bodyMedium.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("Hapus Target?", style: AppFont.h4),
        content: Text("Target tabungan ini akan dihapus permanen.",
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
              Navigator.pop(ctx);
              await _controller.deleteGoal(id);
              _controller.loadGoals(() => setState(() {}));
              _showSnackBar("Target berhasil dihapus 🗑️");
            },
            child: Text("Hapus",
                style: AppFont.bodyMedium.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGoalForm({Map<String, dynamic>? existingGoal}) {
    final titleController =
        TextEditingController(text: existingGoal?['goal_name'] ?? '');
    final amountController = TextEditingController();
    DateTime selectedDate = existingGoal != null
        ? DateTime.parse(existingGoal['deadline'])
        : DateTime.now().add(const Duration(days: 30));

    if (existingGoal != null) {
      String rawAmount =
          existingGoal['target_amount'].toString().replaceAll('.0', '');
      amountController.text = rawAmount.replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 32,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),
                    Text(existingGoal == null ? "Target Baru" : "Edit Target",
                        style: AppFont.h3),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleController,
                      style: AppFont.bodyMedium,
                      decoration: InputDecoration(
                        labelText: "Nama Target (ex: Beli Laptop)",
                        labelStyle: AppFont.subtitle,
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.flag_rounded,
                            color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter()
                      ],
                      style: AppFont.bodyMedium,
                      decoration: InputDecoration(
                        labelText: "Nominal Target",
                        labelStyle: AppFont.subtitle,
                        prefixText: "Rp ",
                        prefixStyle: AppFont.bodyMedium,
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.monetization_on_rounded,
                            color: Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2050),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                    primary: AppColors.primary)),
                            child: child!,
                          ),
                        );
                        if (picked != null)
                          setModalState(() => selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded,
                                color: AppColors.secondary),
                            const SizedBox(width: 12),
                            Text(
                                "Tenggat Waktu: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                style: AppFont.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (titleController.text.trim().isEmpty) {
                            _showErrorDialog("Nama target tidak boleh kosong!");
                            return;
                          }

                          double targetAmount = double.tryParse(
                                  amountController.text.replaceAll(',', '')) ??
                              0.0;
                          if (targetAmount <= 0) {
                            _showErrorDialog(
                                "Nominal target harus lebih dari Rp 0!");
                            return;
                          }

                          await _controller.saveGoal(
                            existingId: existingGoal?['id'],
                            name: titleController.text.trim(),
                            amount: targetAmount,
                            deadline: selectedDate.toIso8601String(),
                          );

                          if (!modalContext.mounted) return;
                          Navigator.pop(modalContext);
                          _controller.loadGoals(() => setState(() {}));
                          _showSnackBar(existingGoal == null
                              ? "Target baru berhasil dibuat! 🎯"
                              : "Target berhasil diperbarui! ✏️");
                        },
                        child: Text("Simpan Target",
                            style: AppFont.bodyMedium
                                .copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddMoneyForm(
      int goalId, String goalName, double target, double current) {
    final amountController = TextEditingController();
    double remaining = target - current;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (modalContext) {
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 32,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 24),
                    Text("Nabung untuk $goalName",
                        style: AppFont.h3, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text("Kurang ${_controller.formatRupiah(remaining)} lagi!",
                        style: AppFont.subtitle),
                    const SizedBox(height: 24),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter()
                      ],
                      style: AppFont.h2,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "0",
                        hintStyle: AppFont.h2.copyWith(color: Colors.white24),
                        prefixText: "Rp ",
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 24),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        onPressed: isProcessing
                            ? null
                            : () async {
                                FocusManager.instance.primaryFocus?.unfocus();
                                double amountToAdd = double.tryParse(
                                        amountController.text
                                            .replaceAll(',', '')) ??
                                    0.0;

                                if (amountToAdd <= 0) {
                                  _showErrorDialog(
                                      "Masukkan nominal yang valid!");
                                  return;
                                }

                                setModalState(() => isProcessing = true);
                                try {
                                  await _controller.addMoneyToGoal(
                                      goalId, amountToAdd, goalName);
                                  if (!modalContext.mounted) return;
                                  Navigator.pop(modalContext);

                                  if (!mounted) return;
                                  _controller.loadGoals(() => setState(() {}));
                                  _showSnackBar(
                                      "Berhasil menabung! Saldo utama telah dipotong. 🎉");
                                } catch (e) {
                                  if (!modalContext.mounted) return;
                                  setModalState(() => isProcessing = false);
                                  if (mounted) {
                                    _showErrorDialog(e
                                        .toString()
                                        .replaceAll('Exception: ', ''));
                                  }
                                }
                              },
                        child: isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3))
                            : Text("Tambahkan Saldo",
                                style: AppFont.bodyMedium
                                    .copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isFromNavbar
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text("Target Tabungan", style: AppFont.h4),
        centerTitle: true,
      ),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => _controller.loadGoals(() => setState(() {})),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Memanggil widget terpisah
                    TargetAIInsightCard(
                      insight: _controller.aiInsight,
                      isFetching: _controller.isFetchingAI,
                      onFetch: () =>
                          _controller.fetchAIInsight(() => setState(() {})),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Wishlist Kamu", style: AppFont.h4),
                        ElevatedButton.icon(
                          onPressed: () => _showGoalForm(),
                          icon: const Icon(Icons.add_rounded,
                              color: AppColors.textPrimary, size: 16),
                          label: Text("Target Baru",
                              style: AppFont.bodySmall
                                  .copyWith(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _controller.goals.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                  "Belum ada target. Yuk buat sekarang!",
                                  style: AppFont.subtitle),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _controller.goals.length,
                            itemBuilder: (context, index) {
                              final goal = _controller.goals[index];
                              double target = goal['target_amount'];
                              double current = goal['current_amount'];

                              return TargetGoalCard(
                                goal: goal,
                                target: target,
                                current: current,
                                progress: (current / target).clamp(0.0, 1.0),
                                isAchieved: current >= target,
                                daysLeft: _controller
                                    .calculateDaysLeft(goal['deadline']),
                                formattedCurrent:
                                    _controller.formatRupiah(current),
                                formattedTarget:
                                    _controller.formatRupiah(target),
                                onEdit: () => _showGoalForm(existingGoal: goal),
                                onDelete: () => _confirmDelete(goal['id']),
                                onAddMoney: () => _showAddMoneyForm(goal['id'],
                                    goal['goal_name'], target, current),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
