import 'package:flutter/material.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
// Nanti kita buat halaman ini, sementara di-comment dulu
// import 'package:arthatrack/screens/transaction/add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FinanceController _financeController = FinanceController();

  double _totalBalance = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Mengambil data Saldo dan Transaksi dari SQLite
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    double balance = await _financeController.getTotalBalance();
    List<Map<String, dynamic>> transactions = await _financeController
        .getUserTransactions();

    setState(() {
      _totalBalance = balance;
      _recentTransactions = transactions;
      _isLoading = false;
    });
  }

  // Format angka ke Rupiah sederhana
  String _formatRupiah(double amount) {
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark theme
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
              onRefresh:
                  _loadDashboardData, // Tarik layar ke bawah untuk refresh
              color: const Color(0xFF00C853),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. KARTU SALDO UTAMA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1A237E),
                            Color(0xFF0D47A1),
                          ], // Warna Biru Bank Premium
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
                          const Text(
                            "Total Saldo",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatRupiah(_totalBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "ArthaTrack Smart Wallet",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(
                                Icons.contactless,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ],
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

                    // 3. DAFTAR TRANSAKSI TERBARU
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Transaksi Terbaru",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Lihat Semua",
                          style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List Transaksi (Jika kosong atau ada isinya)
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
                                : _recentTransactions.length, // Tampilkan max 5
                            itemBuilder: (context, index) {
                              final trx = _recentTransactions[index];
                              bool isIncome = trx['type'] == 'income';
                              return Card(
                                color: const Color(0xFF1E1E1E),
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                                    "${isIncome ? '+' : '-'} ${_formatRupiah(trx['amount'])}",
                                    style: TextStyle(
                                      color: isIncome
                                          ? Colors.green
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
      // 4. BOTTOM NAVIGATION BAR (Syarat Kriteria)
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

  // Widget Bantuan untuk Tombol Aksi Cepat
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
            onPressed: () {
              // Nanti dihubungkan ke form input
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
