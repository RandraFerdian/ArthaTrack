import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
import 'package:arthatrack/screens/transaction/add_transaction_screen.dart';

class TargetScreen extends StatefulWidget {
  const TargetScreen({super.key});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  final FinanceController _financeController = FinanceController();
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;
  String _aiInsight =
      "Lihat apa kata Artha AI tentang progres dan target tabunganmu!";
  bool _isFetchingAI = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await _financeController.getUserSavingsGoals();

    goals.sort((a, b) {
      bool aAchieved = a['current_amount'] >= a['target_amount'];
      bool bAchieved = b['current_amount'] >= b['target_amount'];
      if (aAchieved == bAchieved) {
        return DateTime.parse(
          a['deadline'],
        ).compareTo(DateTime.parse(b['deadline']));
      }
      return aAchieved ? 1 : -1;
    });

    if (mounted) {
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAIInsight() async {
    setState(() => _isFetchingAI = true);
    final insight = await _financeController.getQuickAIInsight('target');
    if (mounted) {
      setState(() {
        _aiInsight = insight;
        _isFetchingAI = false;
      });
    }
  }

  String _formatRupiah(double amount) {
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  int _calculateDaysLeft(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime target = DateTime(deadline.year, deadline.month, deadline.day);
      return target.difference(today).inDays;
    } catch (e) {
      return 0;
    }
  }

  void _showGoalForm({Map<String, dynamic>? existingGoal}) {
    final titleController = TextEditingController(
      text: existingGoal?['goal_name'] ?? '',
    );
    final amountController = TextEditingController();
    DateTime selectedDate = existingGoal != null
        ? DateTime.parse(existingGoal['deadline'])
        : DateTime.now().add(const Duration(days: 30));

    if (existingGoal != null) {
      String rawAmount = existingGoal['target_amount'].toString().replaceAll(
        '.0',
        '',
      );
      amountController.text = rawAmount.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 32,
              ),
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    existingGoal == null ? "Target Baru" : "Edit Target",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Nama Target (ex: Beli Laptop)",
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.flag_rounded,
                        color: Colors.indigoAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Nominal Target",
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixText: "Rp ",
                      prefixStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.monetization_on_rounded,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2050),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.indigoAccent,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null)
                        setModalState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.tealAccent,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Tenggat Waktu: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (titleController.text.isEmpty ||
                            amountController.text.isEmpty)
                          return;
                        double targetAmount =
                            double.tryParse(
                              amountController.text.replaceAll(',', ''),
                            ) ??
                            0.0;
                        if (targetAmount <= 0) return;
                        if (existingGoal == null) {
                          await _financeController.addSavingsGoal(
                            titleController.text,
                            targetAmount,
                            selectedDate.toIso8601String(),
                          );
                        } else {
                          await _financeController.updateSavingsGoal(
                            existingGoal['id'],
                            titleController.text,
                            targetAmount,
                            selectedDate.toIso8601String(),
                          );
                        }
                        Navigator.pop(context);
                        _loadGoals();
                      },
                      child: const Text(
                        "Simpan Target",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddMoneyForm(
    int goalId,
    String goalName,
    double target,
    double current,
  ) {
    final amountController = TextEditingController();
    double remaining = target - current;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Nabung untuk $goalName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Kurang ${_formatRupiah(remaining)} lagi!",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "0",
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixText: "Rp ",
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 24),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () async {
                              double amountToAdd =
                                  double.tryParse(
                                    amountController.text.replaceAll(',', ''),
                                  ) ??
                                  0.0;
                              if (amountToAdd <= 0) return;
                              setModalState(() => isProcessing = true);
                              try {
                                await _financeController.addMoneyToGoal(
                                  goalId,
                                  amountToAdd,
                                  goalName,
                                );
                                if (!modalContext.mounted) return;
                                Navigator.pop(modalContext);
                                if (!mounted) return;
                                _loadGoals();
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Berhasil menabung! Saldo utama telah dipotong.",
                                    ),
                                    backgroundColor: Color(0xFF00C853),
                                  ),
                                );
                              } catch (e) {
                                if (!modalContext.mounted) return;
                                setModalState(() => isProcessing = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              "Tambahkan Saldo",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Hapus Target?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Target tabungan ini akan dihapus permanen.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _financeController.deleteSavingsGoal(id);
              _loadGoals();
            },
            child: const Text(
              "Hapus",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Target Tabungan",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent),
            )
          : RefreshIndicator(
              onRefresh: _loadGoals,
              color: Colors.indigoAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAIInsightCard(), // Memanggil Insight dari Gemini
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Wishlist Kamu",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showGoalForm(),
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: const Text(
                            "Target Baru",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _goals.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                "Belum ada target. Yuk buat sekarang!",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _goals.length,
                            itemBuilder: (context, index) {
                              final goal = _goals[index];
                              double target = goal['target_amount'];
                              double current = goal['current_amount'];
                              double progress = (current / target).clamp(
                                0.0,
                                1.0,
                              );
                              bool isAchieved = current >= target;
                              int daysLeft = _calculateDaysLeft(
                                goal['deadline'],
                              );

                              return Card(
                                color: const Color(0xFF1E1E1E),
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isAchieved
                                                  ? Colors.green.withOpacity(
                                                      0.2,
                                                    )
                                                  : Colors.indigoAccent
                                                        .withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isAchieved
                                                  ? Icons.emoji_events_rounded
                                                  : Icons.flag_rounded,
                                              color: isAchieved
                                                  ? Colors.green
                                                  : Colors.indigoAccent,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  goal['goal_name'],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  isAchieved
                                                      ? "Target Tercapai! 🎉"
                                                      : (daysLeft < 0
                                                            ? "Terlambat ${daysLeft.abs()} hari"
                                                            : "Sisa $daysLeft hari"),
                                                  style: TextStyle(
                                                    color: isAchieved
                                                        ? Colors.green
                                                        : (daysLeft <= 7
                                                              ? Colors.redAccent
                                                              : Colors.grey),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            color: const Color(0xFF2A2A2A),
                                            icon: const Icon(
                                              Icons.more_vert_rounded,
                                              color: Colors.grey,
                                            ),
                                            onSelected: (value) {
                                              if (value == 'edit')
                                                _showGoalForm(
                                                  existingGoal: goal,
                                                );
                                              if (value == 'delete')
                                                _confirmDelete(goal['id']);
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      "Edit",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      color: Colors.redAccent,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      "Hapus",
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatRupiah(current),
                                            style: TextStyle(
                                              color: isAchieved
                                                  ? Colors.green
                                                  : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            "dari ${_formatRupiah(target)}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 8,
                                          backgroundColor: const Color(
                                            0xFF2A2A2A,
                                          ),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                isAchieved
                                                    ? Colors.green
                                                    : Colors.indigoAccent,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (!isAchieved)
                                        SizedBox(
                                          width: double.infinity,
                                          height: 40,
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showAddMoneyForm(
                                              goal['id'],
                                              goal['goal_name'],
                                              target,
                                              current,
                                            ),
                                            icon: const Icon(
                                              Icons.add_circle_outline_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              "Nabung",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Colors.indigoAccent,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E1E),
            Colors.indigo.shade900.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.indigoAccent.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigoAccent.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFB388FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Artha AI Target Insight",
                style: TextStyle(
                  color: Color(0xFFB388FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _aiInsight,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),
          // TOMBOL MANUAL TRIGGER AI
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _isFetchingAI ? null : _fetchAIInsight,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isFetchingAI
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
              label: Text(
                _isFetchingAI ? "Menganalisis..." : "✨ Dapatkan Motivasi AI",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
