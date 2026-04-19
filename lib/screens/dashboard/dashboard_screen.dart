import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
import 'package:arthatrack/screens/transaction/add_transaction_screen.dart';
import 'package:arthatrack/screens/transaction/currency_conversion_screen.dart';
import 'package:arthatrack/controllers/currency_controller.dart';
import 'package:arthatrack/screens/transaction/transaction_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FinanceController _financeController = FinanceController();
  final CurrencyController _currencyController = CurrencyController();

  double _totalBalance = 0.0;
  double _displayBalance = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  String _selectedCurrency = 'IDR';
  bool _isLoading = true;
  bool _isConverting = false;

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
    List<Map<String, dynamic>> transactions = await _financeController
        .getUserTransactions();

    setState(() {
      _totalBalance = balance;
      _displayBalance = balance; // Default sama dengan total asli
      _recentTransactions = transactions;
      _isLoading = false;
      _selectedCurrency = 'IDR';
    });
  }

  Future<void> _changeDisplayCurrency(String code) async {
    if (code == 'IDR') {
      setState(() {
        _displayBalance =
            _totalBalance; // [DIPERBAIKI] Menggunakan _totalBalance
        _selectedCurrency = 'IDR';
      });
      return;
    }

    setState(() => _isConverting = true);

    double? result = await _currencyController.convertCurrency(
      fromCurrency: 'IDR',
      toCurrency: code,
      amount: _totalBalance, // [DIPERBAIKI] Menggunakan _totalBalance
    );

    setState(() {
      _isConverting = false;
      if (result != null) {
        _displayBalance = result;
        _selectedCurrency = code;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengonversi. Cek internet.")),
        );
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

  // [DIPERBAIKI] Menerima 2 parameter: angka dan mata uangnya
  String _formatDisplay(double amount, String code) {
    final Map<String, String> currencySymbols = {
      'IDR': 'IDR',
      'USD': 'USD',
      'EUR': 'EUR',
      'JPY': 'JPY',
      'GBP': 'GBP',
      'MYR': 'MYR',
      'SGD': 'SGD',
      'AUD': 'AUD',
      'CAD': 'CAD',
      'CHF': 'CHF',
      'CNY': 'CNY',
      'KRW': 'KRW',
    };
    String symbol = currencySymbols[code] ?? code;
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

    return "$symbol $finalAmount";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Selamat Datang,",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              "User ArthaTrack",
              style: TextStyle(
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
              color: const Color(0xFF00C853),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. KARTU SALDO UTAMA (BISA DIKLIK)
                    GestureDetector(
                      onTap:
                          _showCurrencySelector, // [DIPERBAIKI] Fungsi klik ditambah
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A237E).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _selectedCurrency,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Tampilkan Indikator Loading kalau lagi proses konversi API
                            _isConverting
                                ? const SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _formatDisplay(
                                      _displayBalance,
                                      _selectedCurrency,
                                    ), // [DIPERBAIKI] Panggil format yang benar
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            const SizedBox(height: 24),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "ArthaTrack Smart Wallet",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                Icon(Icons.contactless, color: Colors.white54),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 2. TOMBOL AKSI CEPAT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          Icons.arrow_downward,
                          "Pemasukan",
                          Colors.green,
                        ),
                        _buildActionButton(
                          Icons.arrow_upward,
                          "Pengeluaran",
                          Colors.redAccent,
                        ),
                        _buildActionButton(
                          Icons.compare_arrows,
                          "Konversi",
                          Colors.orange,
                        ),
                        _buildActionButton(
                          Icons.more_horiz,
                          "Lainnya",
                          Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

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
                          onTap: () {
                            // Navigasi ke Halaman Riwayat Transaksi saat "Lihat Semua" diklik
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TransactionHistoryScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Lihat Semua",
                            style: TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _recentTransactions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                "Belum ada transaksi bulan ini.",
                                style: TextStyle(color: Colors.grey),
                              ),
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
                                  // Panggil fungsi showTransactionDetail yang kita buat di file history tadi
                                  onTap: () => showTransactionDetail(
                                    context,
                                    trx,
                                    amountStr,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isIncome
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.redAccent.withOpacity(0.2),
                                      child: Icon(
                                        isIncome
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
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
                                      "${isIncome ? '+' : '-'} $amountStr",
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
                  ],
                ),
              ),
            ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF00C853),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "Statistik",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: "Target",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: 28),
            onPressed: () async {
              if (label == "Pemasukan" || label == "Pengeluaran") {
                String type = label == "Pemasukan" ? "income" : "expense";
                bool? shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddTransactionScreen(initialType: type),
                  ),
                );
                if (shouldRefresh == true) {
                  _loadDashboardData();
                }
              } else if (label == "Konversi") {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CurrencyConversionScreen(),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
