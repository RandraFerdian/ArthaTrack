import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import package baru
import 'package:arthatrack/controllers/finance_controller.dart';

// FUNGSI GLOBAL: Menampilkan Modal Detail Transaksi
void showTransactionDetail(
  BuildContext context,
  Map<String, dynamic> trx,
  String displayAmount,
) {
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trx['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
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

            // Baris Lokasi yang Bisa Diklik ke Google Maps
            _buildDetailRow(
              Icons.location_on_rounded,
              "Lokasi (GPS)",
              hasLocation
                  ? "${trx['latitude']}, ${trx['longitude']}"
                  : "Lokasi tidak tercatat",
              isLink: hasLocation,
              onTap: hasLocation
                  ? () async {
                      final double lat = trx['latitude'];
                      final double lng = trx['longitude'];
                      // Format URL resmi pencarian Google Maps
                      final Uri googleMapsUrl = Uri.parse(
                        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
                      );

                      if (await canLaunchUrl(googleMapsUrl)) {
                        // Memaksa buka di aplikasi luar (bukan di browser internal aplikasi)
                        await launchUrl(
                          googleMapsUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Tidak dapat membuka Google Maps"),
                          ),
                        );
                      }
                    }
                  : null,
            ),

            const SizedBox(height: 32),
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

// Widget Builder dengan tambahan fitur `isLink` dan `onTap`
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
                      color: isLink
                          ? const Color(0xFF00C853)
                          : Colors.white, // Teks jadi hijau jika berupa link
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: isLink
                          ? TextDecoration.underline
                          : TextDecoration.none, // Garis bawah untuk link
                      decorationColor: const Color(0xFF00C853),
                    ),
                  ),
                ],
              ),
            ),
            // Tambahan Icon Panah keluar jika itu adalah Link Gmaps
            if (isLink)
              const Icon(
                Icons.open_in_new_rounded,
                color: Color(0xFF00C853),
                size: 20,
              ),
          ],
        ),
      ),
    ),
  );
}

// ==========================================
// KELAS UTAMA: TransactionHistoryScreen
// ==========================================
class TransactionHistoryScreen extends StatefulWidget {
  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FinanceController _financeController = FinanceController();
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];

  bool _isLoading = true;
  String _selectedMonth = "Semua";
  List<String> _availableMonths = ["Semua"];

  @override
  void initState() {
    super.initState();
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
      _filteredTransactions = transactions;
      _availableMonths = monthsSet.toList();
      _isLoading = false;
    });
  }

  void _filterByMonth(String month) {
    setState(() {
      _selectedMonth = month;
      if (month == "Semua") {
        _filteredTransactions = _allTransactions;
      } else {
        _filteredTransactions = _allTransactions.where((trx) {
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
            return "${monthNames[date.month - 1]} ${date.year}" == month;
          } catch (e) {
            return false;
          }
        }).toList();
      }
    });
  }

  String _formatRupiah(double amount) {
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
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
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _availableMonths.length,
                    itemBuilder: (context, index) {
                      String month = _availableMonths[index];
                      bool isSelected = _selectedMonth == month;
                      return GestureDetector(
                        onTap: () => _filterByMonth(month),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00C853)
                                : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            month,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

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

                            return Card(
                              color: const Color(0xFF1E1E1E),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => showTransactionDetail(
                                  context,
                                  trx,
                                  amountText,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isIncome
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.redAccent.withOpacity(0.15),
                                    child: Icon(
                                      isIncome
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: isIncome
                                          ? Colors.green
                                          : Colors.redAccent,
                                    ),
                                  ),
                                  title: Text(
                                    trx['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    trx['category'],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    "${isIncome ? '+' : '-'} $amountText",
                                    style: TextStyle(
                                      color: isIncome
                                          ? Colors.green
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
