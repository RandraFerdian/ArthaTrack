import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
import 'package:arthatrack/screens/transaction/add_transaction_screen.dart';
import 'package:arthatrack/screens/transaction/currency_conversion_screen.dart';
import 'package:arthatrack/controllers/currency_controller.dart';
import 'package:arthatrack/screens/transaction/transaction_history_screen.dart';
import 'package:arthatrack/controllers/auth_controller.dart';
import 'package:arthatrack/screens/target/target_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FinanceController _financeController = FinanceController();
  final CurrencyController _currencyController = CurrencyController();
  final AuthController _authController = AuthController();

  double _totalBalance = 0.0;
  double _displayBalance = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  String _selectedCurrency = 'IDR';
  bool _isLoading = true;
  bool _isConverting = false;
  String _userName = "User";

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastRefreshTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initAccelerometer();
  }

  void _initAccelerometer() {
    _accelerometerSubscription = userAccelerometerEventStream().listen((
      UserAccelerometerEvent event,
    ) {
      double acceleration = sqrt(
        pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2),
      );
      if (acceleration > 15) {
        final now = DateTime.now();
        if (now.difference(_lastRefreshTime).inSeconds > 3) {
          _lastRefreshTime = now;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("🔄 Memperbarui data saldo & transaksi..."),
                duration: Duration(seconds: 1),
                backgroundColor: Color(0xFF1A237E),
              ),
            );
          }
          _loadDashboardData();
        }
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    double balance = await _financeController.getTotalBalance();

    // Ambil data transaksi (TIDAK PERLU DI-SORT LAGI karena SQLite sudah melakukan ORDER BY date DESC otomatis)
    List<Map<String, dynamic>> transactions = await _financeController
        .getUserTransactions();

    String? name = await _authController.getLoggedInUserName();

    setState(() {
      _totalBalance = balance;
      _displayBalance = balance;
      _recentTransactions = transactions;
      _userName = name ?? "User";
      _isLoading = false; // Sekarang pasti akan tereksekusi
      _selectedCurrency = 'IDR';
    });
  }

  Future<void> _changeDisplayCurrency(String code) async {
    if (code == 'IDR') {
      setState(() {
        _displayBalance = _totalBalance;
        _selectedCurrency = 'IDR';
      });
      return;
    }
    setState(() => _isConverting = true);
    double? result = await _currencyController.convertCurrency(
      fromCurrency: 'IDR',
      toCurrency: code,
      amount: _totalBalance,
    );
    setState(() {
      _isConverting = false;
      if (result != null) {
        _displayBalance = result;
        _selectedCurrency = code;
      }
    });
  }

  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['IDR', 'USD', 'EUR', 'JPY', 'SGD']
              .map(
                (code) => ListTile(
                  title: Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: _selectedCurrency == code
                      ? const Icon(Icons.check_circle, color: Color(0xFF00C853))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _changeDisplayCurrency(code);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _formatDisplay(double amount, String code) {
    int decimals = (code == 'IDR' || code == 'JPY') ? 0 : 2;
    String amountStr = amount.toStringAsFixed(decimals);
    List<String> parts = amountStr.split('.');
    String formattedInteger = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    String finalAmount = parts.length > 1
        ? "$formattedInteger.${parts[1]}"
        : formattedInteger;
    if (code == 'IDR') return "Rp $finalAmount";
    return "$code $finalAmount";
  }

  // =========================================================
  // FUNGSI MODAL DETAIL (DITAMBAHKAN AGAR BISA EDIT DI DASHBOARD)
  // =========================================================
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
                          "https://www.google.com/maps/search/?api=1&query=${trx['latitude']}, ${trx['longitude']}",
                        );
                        if (await canLaunchUrl(googleMapsUrl))
                          await launchUrl(
                            googleMapsUrl,
                            mode: LaunchMode.externalApplication,
                          );
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
                        Navigator.pop(context); // Tutup modal
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(
                              initialType: trx['type'],
                              existingTransaction: trx,
                            ),
                          ),
                        ).then(
                          (_) => _loadDashboardData(),
                        ); // Refresh Dashboard setelah edit
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
              _loadDashboardData(); // Refresh Data Dashboard
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
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selamat Datang,",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              _userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C853)),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KARTU SALDO
                    GestureDetector(
                      onTap: _showCurrencySelector,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Saldo",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _selectedCurrency,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _isConverting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    _formatDisplay(
                                      _displayBalance,
                                      _selectedCurrency,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // MENU CEPAT
                    const Text(
                      "Menu Cepat",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.9,
                      children: [
                        _buildActionButton(
                          Icons.add_circle_outline_rounded,
                          "Pemasukan",
                          Colors.green,
                          "income",
                        ),
                        _buildActionButton(
                          Icons.remove_circle_outline_rounded,
                          "Pengeluaran",
                          Colors.redAccent,
                          "expense",
                        ),
                        _buildActionButton(
                          Icons.currency_exchange_rounded,
                          "Konversi",
                          Colors.orange,
                          "conversion",
                        ),
                        _buildActionButton(
                          Icons.map_rounded,
                          "Peta Lokasi",
                          Colors.teal,
                          "maps",
                        ),
                        _buildActionButton(
                          Icons.cloud_sync_rounded,
                          "Cloud Sync",
                          Colors.blue,
                          "sync",
                        ),
                        _buildActionButton(
                          Icons.track_changes_rounded,
                          "Target",
                          Colors.indigo,
                          "target",
                        ),
                        _buildActionButton(
                          Icons.emoji_events_rounded,
                          "Tantangan",
                          Colors.amber,
                          "challenge",
                        ),
                        _buildActionButton(
                          Icons.sports_esports_rounded,
                          "Game",
                          Colors.purpleAccent,
                          "game",
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // TRANSAKSI TERBARU
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Transaksi Terbaru",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TransactionHistoryScreen(),
                            ),
                          ).then((_) => _loadDashboardData()),
                          child: const Text(
                            "Lihat Semua",
                            style: TextStyle(
                              color: Color(0xFF00C853),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _recentTransactions.isEmpty
                        ? const Center(
                            child: Text(
                              "Belum ada transaksi.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentTransactions.length > 5
                                ? 5
                                : _recentTransactions.length,
                            itemBuilder: (context, index) {
                              final trx = _recentTransactions[index];
                              bool isIncome = trx['type'] == 'income';
                              String amountStr = _formatDisplay(
                                trx['amount'],
                                'IDR',
                              );

                              return Card(
                                color: const Color(0xFF1E1E1E),
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  // [DIPERBAIKI] Memanggil _showTransactionDetail yang baru kita tambahkan
                                  onTap: () =>
                                      _showTransactionDetail(trx, amountStr),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isIncome
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.redAccent.withOpacity(
                                                  0.2,
                                                ),
                                          child: Icon(
                                            isIncome
                                                ? Icons.arrow_downward
                                                : Icons.arrow_upward,
                                            color: isIncome
                                                ? Colors.green
                                                : Colors.redAccent,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                trx['title'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
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
                                            "${isIncome ? '+' : '-'} $amountStr",
                                            style: TextStyle(
                                              color: isIncome
                                                  ? Colors.green
                                                  : Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
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
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    String actionId,
  ) {
    return GestureDetector(
      onTap: () async {
        if (actionId == "income" || actionId == "expense") {
          bool? shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(initialType: actionId),
            ),
          );
          if (shouldRefresh == true) _loadDashboardData();
        } else if (actionId == "conversion") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CurrencyConversionScreen()),
          );
        } else if (actionId == "target") {
          // [DIPERBAIKI] Sekarang tombol Target langsung membuka TargetScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TargetScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Fitur $label segera hadir!"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
