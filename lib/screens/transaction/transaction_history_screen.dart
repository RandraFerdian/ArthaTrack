import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
import 'package:arthatrack/screens/transaction/add_transaction_screen.dart'; // Penting untuk Edit

class TransactionHistoryScreen extends StatefulWidget {
  final String? initialFilter;
  const TransactionHistoryScreen({super.key, this.initialFilter});

  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FinanceController _financeController = FinanceController();

  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;

  String _selectedTypeFilter = 'all';
  String _selectedMonth = "Semua";
  List<String> _availableMonths = ["Semua"];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _selectedTypeFilter = widget.initialFilter!;
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    List<Map<String, dynamic>> transactions = await _financeController
        .getUserTransactions();

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

    setState(() {
      _allTransactions = transactions;
      _availableMonths = monthsSet.toList();
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((trx) {
        if (_selectedTypeFilter != 'all' &&
            trx['type'] != _selectedTypeFilter) {
          return false;
        }
        if (_selectedMonth != "Semua") {
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
            if (trxMonth != _selectedMonth) return false;
          } catch (e) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  String _getDateHeader(String dateStr) {
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

  void _setTypeFilter(String type) {
    setState(() => _selectedTypeFilter = type);
    _applyFilters();
  }

  void _setMonthFilter(String month) {
    setState(() => _selectedMonth = month);
    _applyFilters();
  }

  String _formatRupiah(double amount) {
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  // MODAL DETAIL & AKSI
  void _showTransactionDetail(Map<String, dynamic> trx, String displayAmount) {
    bool isIncome = trx['type'] == 'income';
    bool hasLocation = trx['latitude'] != null && trx['longitude'] != null;

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
        'Des',
      ];
      formattedDate =
          "${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isIncome
                      ? Colors.green.withOpacity(0.15)
                      : Colors.redAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isIncome ? Colors.green : Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "${isIncome ? '+' : '-'} $displayAmount",
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.redAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                trx['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              _buildDetailRow(
                Icons.category_rounded,
                "Kategori",
                trx['category'],
              ),
              _buildDetailRow(
                Icons.calendar_today_rounded,
                "Tanggal",
                formattedDate,
              ),
              _buildDetailRow(
                Icons.location_on_rounded,
                "Lokasi (GPS)",
                hasLocation
                    ? "${trx['latitude']}, ${trx['longitude']}"
                    : "Lokasi tidak tercatat",
                isLink: hasLocation,
                onTap: hasLocation
                    ? () async {
                        final Uri googleMapsUrl = Uri.parse(
                          "http://googleusercontent.com/maps.google.com/maps?q=${trx['latitude']},${trx['longitude']}",
                        );
                        if (await canLaunchUrl(googleMapsUrl)) {
                          await launchUrl(
                            googleMapsUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    : null,
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(trx['id']),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        "Hapus",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(
                              initialType: trx['type'],
                              existingTransaction: trx,
                            ),
                          ),
                        ).then((_) => _loadHistory());
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Edit",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
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
                    backgroundColor: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Tutup",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          "Hapus Transaksi?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Data yang dihapus tidak bisa dikembalikan.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await _financeController.deleteTransaction(id);
              _loadHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Transaksi dihapus")),
              );
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

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
    VoidCallback? onTap,
  }) {
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
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: isLink ? const Color(0xFF00C853) : Colors.white,
                        fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    // === HITUNG TOTAL UNTUK SUMMARY CARD ===
    double currentIncome = 0;
    double currentExpense = 0;
    for (var trx in _filteredTransactions) {
      if (trx['type'] == 'income') {
        currentIncome += trx['amount'];
      } else {
        currentExpense += trx['amount'];
      }
    }

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
          "Riwayat Transaksi",
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
              child: CircularProgressIndicator(color: Color(0xFF00C853)),
            )
          : Column(
              children: [
                // 1. FILTER TIPE (Pemasukan / Pengeluaran)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        _buildTypeTab('all', 'Semua'),
                        _buildTypeTab('income', 'Pemasukan'),
                        _buildTypeTab('expense', 'Pengeluaran'),
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
                    itemCount: _availableMonths.length,
                    itemBuilder: (context, index) {
                      String month = _availableMonths[index];
                      bool isSelected = _selectedMonth == month;
                      return GestureDetector(
                        onTap: () => _setMonthFilter(month),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00C853).withOpacity(0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00C853)
                                  : Colors.white24,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            month,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00C853)
                                  : Colors.grey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // === 3. KARTU SUMMARY TOTAL ===
                if (_filteredTransactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF1A237E,
                        ).withOpacity(0.3), // Warna biru elegan
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1A237E).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Total Pemasukan",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "+ ${_formatRupiah(currentIncome)}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Total Pengeluaran",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "- ${_formatRupiah(currentExpense)}",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 4. DAFTAR TRANSAKSI
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? const Center(
                          child: Text(
                            "Tidak ada transaksi.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final trx = _filteredTransactions[index];
                            bool isIncome = trx['type'] == 'income';
                            String amountText = _formatRupiah(trx['amount']);

                            // LOGIKA PENGELOMPOKKAN TANGGAL
                            final String currentHeader = _getDateHeader(
                              trx['date'],
                            );
                            final String? prevHeader = index > 0
                                ? _getDateHeader(
                                    _filteredTransactions[index - 1]['date'],
                                  )
                                : null;
                            bool isNewDay = currentHeader != prevHeader;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isNewDay)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 16,
                                      bottom: 8,
                                      left: 4,
                                    ),
                                    child: Text(
                                      currentHeader,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                Card(
                                  color: const Color(0xFF1E1E1E),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () =>
                                        _showTransactionDetail(trx, amountText),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: isIncome
                                                ? Colors.green.withOpacity(0.15)
                                                : Colors.redAccent.withOpacity(
                                                    0.15,
                                                  ),
                                            child: Icon(
                                              isIncome
                                                  ? Icons.arrow_downward_rounded
                                                  : Icons.arrow_upward_rounded,
                                              color: isIncome
                                                  ? Colors.green
                                                  : Colors.redAccent,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  trx['title'],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  trx['category'],
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            flex: 2,
                                            child: Text(
                                              "${isIncome ? '+' : '-'} $amountText",
                                              style: TextStyle(
                                                color: isIncome
                                                    ? Colors.green
                                                    : Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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

  Widget _buildTypeTab(String type, String title) {
    bool isSelected = _selectedTypeFilter == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setTypeFilter(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2A2A2A) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
