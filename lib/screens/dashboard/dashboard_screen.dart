import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arthatrack/controllers/dashboard_controller.dart';
import 'package:arthatrack/src/core/app_routes.dart';
import 'package:arthatrack/src/core/session_manager.dart';
import 'package:arthatrack/screens/dashboard/dashboard_widget.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardController _controller;

  late StreamSubscription<UserAccelerometerEvent> _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.init();
    _controller.loadDashboardData(() => setState(() {}));
    _initAccelerometer();
  }

  void _initAccelerometer() {
    _accelerometerSubscription = userAccelerometerEventStream()
        .listen((UserAccelerometerEvent event) async {
      if (!SessionManager.accelEnabled) return;

      double acceleration = sqrt(
        pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2),
      );

      if (acceleration > 15) {
        final now = DateTime.now();
        if (now.difference(_controller.lastRefreshTime).inSeconds > 3) {
          _controller.lastRefreshTime = now;
          _controller.loadDashboardData(() => setState(() {}));
        }
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['IDR', 'USD', 'EUR', 'JPY', 'SGD']
              .map((code) => ListTile(
                    title: Text(code,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: _controller.selectedCurrency == code
                        ? const Icon(Icons.check_circle,
                            color: Color(0xFF00C853))
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _controller.changeDisplayCurrency(
                          code, () => setState(() {}));
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

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
        'Des'
      ];
      formattedDate =
          "${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
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
                    color: isIncome
                        ? Colors.green.withOpacity(0.15)
                        : Colors.redAccent.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isIncome ? Colors.green : Colors.redAccent,
                    size: 40),
              ),
              const SizedBox(height: 20),
              Text("${isIncome ? '+' : '-'} $displayAmount",
                  style: TextStyle(
                      color: isIncome ? Colors.green : Colors.redAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(trx['title'],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
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
                        final Uri googleMapsUrl = Uri.parse(
                            "https://www.google.com/maps/search/?api=1&query=${trx['latitude']}, ${trx['longitude']}");
                        if (await canLaunchUrl(googleMapsUrl))
                          await launchUrl(googleMapsUrl,
                              mode: LaunchMode.externalApplication);
                      }
                    : null,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(trx['id']),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      label: const Text("Hapus",
                          style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.addTransaction,
                          arguments: {
                            'initialType': trx['type'],
                            'existingTransaction': trx,
                          },
                        ).then((_) => _controller
                            .loadDashboardData(() => setState(() {})));
                      },
                      icon:
                          const Icon(Icons.edit_outlined, color: Colors.white),
                      label: const Text("Edit",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
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
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0),
                  child: const Text("Tutup",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
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
        title: const Text("Hapus Transaksi?",
            style: TextStyle(color: Colors.white)),
        content: const Text("Data yang dihapus tidak bisa dikembalikan.",
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("Batal", style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await _controller.deleteTransaction(id);
              _controller.loadDashboardData(() => setState(() {}));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Transaksi dihapus")));
            },
            child:
                const Text("Hapus", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
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
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: TextStyle(
                            color:
                                isLink ? const Color(0xFF00C853) : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: isLink
                                ? TextDecoration.underline
                                : TextDecoration.none)),
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selamat Datang,",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            Text(_controller.userName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.search_rounded, color: Colors.white, size: 28),
            onPressed: () async {
              // Memanggil class SearchDelegate yang kita buat di bawah
              final selectedFeature = await showSearch(
                context: context,
                delegate: FeatureSearchDelegate(),
              );
              // Jika user memilih sesuatu, pindah ke halaman tersebut
              if (selectedFeature != null) {
                _controller.navigateToFeature(context, selectedFeature);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C853)))
          : RefreshIndicator(
              onRefresh: () async =>
                  _controller.loadDashboardData(() => setState(() {})),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KARTU SALDO
                    BalanceCard(
                      selectedCurrency: _controller.selectedCurrency,
                      isConverting: _controller.isConverting,
                      formattedBalance: _controller.formatCurrency(
                          _controller.displayBalance,
                          _controller.selectedCurrency),
                      onTap: _showCurrencySelector,
                    ),
                    const SizedBox(height: 24),

                    // MENU CEPAT
                    const Text("Menu Cepat",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.9,
                      children: [
                        ActionButton(
                            icon: Icons.add_circle_outline_rounded,
                            label: "Pemasukan",
                            color: Colors.green,
                            onTap: () => _controller.navigateToFeature(
                                context, "income")),
                        ActionButton(
                            icon: Icons.remove_circle_outline_rounded,
                            label: "Pengeluaran",
                            color: Colors.redAccent,
                            onTap: () => _controller.navigateToFeature(
                                context, "expense")),
                        ActionButton(
                            icon: Icons.currency_exchange_rounded,
                            label: "Konversi",
                            color: Colors.orange,
                            onTap: () => _controller.navigateToFeature(
                                context, "conversion")),
                        ActionButton(
                            icon: Icons.map_rounded,
                            label: "Peta Lokasi",
                            color: Colors.teal,
                            onTap: () =>
                                _controller.navigateToFeature(context, "maps")),
                        ActionButton(
                            icon: Icons.language_rounded,
                            label: "Timezone",
                            color: Colors.blue,
                            onTap: () => _controller.navigateToFeature(
                                context, "time_conversion")),
                        ActionButton(
                            icon: Icons.track_changes_rounded,
                            label: "Target",
                            color: Colors.indigo,
                            onTap: () => _controller.navigateToFeature(
                                context, "target")),
                        ActionButton(
                            icon: Icons.auto_awesome_rounded,
                            label: "Chat AI",
                            color: Colors.amber,
                            onTap: () => _controller.navigateToFeature(
                                context, "chat_ai")),
                        ActionButton(
                            icon: Icons.sports_esports_rounded,
                            label: "Game",
                            color: Colors.purpleAccent,
                            onTap: () =>
                                _controller.navigateToFeature(context, "game")),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // TRANSAKSI TERBARU
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Transaksi Terbaru",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () =>
                              _controller.navigateToFeature(context, "history"),
                          child: const Text("Lihat Semua",
                              style: TextStyle(
                                  color: Color(0xFF00C853),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _controller.recentTransactions.isEmpty
                        ? const Center(
                            child: Text("Belum ada transaksi.",
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _controller.recentTransactions.length > 5
                                ? 5
                                : _controller.recentTransactions.length,
                            itemBuilder: (context, index) {
                              final trx = _controller.recentTransactions[index];
                              String amountStr = _controller.formatCurrency(
                                  trx['amount'], 'IDR');

                              return TransactionCard(
                                trx: trx,
                                amountStr: amountStr,
                                onTap: () =>
                                    _showTransactionDetail(trx, amountStr),
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

// =========================================================
// CLASS CUSTOM SEARCH DELEGATE
// =========================================================
class FeatureSearchDelegate extends SearchDelegate<String?> {
  // Daftar semua fitur yang ada di ArthaTrack berserta kata kunci pencariannya
  final List<Map<String, dynamic>> features = [
    {
      'name': 'Pemasukan Baru',
      'desc': 'Tambah catatan uang masuk',
      'icon': Icons.add_circle_outline_rounded,
      'action': 'income'
    },
    {
      'name': 'Pengeluaran Baru',
      'desc': 'Tambah catatan uang keluar',
      'icon': Icons.remove_circle_outline_rounded,
      'action': 'expense'
    },
    {
      'name': 'Konversi Mata Uang',
      'desc': 'Ubah nilai dari USD, EUR, dll',
      'icon': Icons.currency_exchange_rounded,
      'action': 'conversion'
    },
    {
      'name': 'Peta Lokasi',
      'desc': 'Lihat riwayat transaksi di map',
      'icon': Icons.map_rounded,
      'action': 'maps'
    },
    {
      'name': 'Timezone',
      'desc': 'Konversi zona waktu dunia',
      'icon': Icons.language_rounded,
      'action': 'time_conversion'
    },
    {
      'name': 'Target Tabungan',
      'desc': 'Cek progress impianmu',
      'icon': Icons.track_changes_rounded,
      'action': 'target'
    },
    {
      'name': 'Chat AI Artha',
      'desc': 'Tanya asisten keuangan cerdas',
      'icon': Icons.auto_awesome_rounded,
      'action': 'chat_ai'
    },
    {
      'name': 'Minigame',
      'desc': 'Main kuis tebak mata uang',
      'icon': Icons.sports_esports_rounded,
      'action': 'game'
    },
    {
      'name': 'Riwayat Transaksi',
      'desc': 'Lihat semua histori keuangan',
      'icon': Icons.history_rounded,
      'action': 'history'
    },
  ];

  // Mengubah tema layar pencarian agar sesuai dengan Dark Mode aplikasi
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Cari fitur aplikasi...';

  // Tombol X di sebelah kanan untuk menghapus teks pencarian
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            query = '';
          },
        )
    ];
  }

  // Tombol kembali di sebelah kiri
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: Colors.white, size: 20),
      onPressed: () {
        close(context, null); // Tutup pencarian tanpa hasil
      },
    );
  }

  // Hasil saat pengguna menekan Enter (kita samakan saja dengan Suggestion)
  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  // Hasil yang muncul saat pengguna mengetik huruf demi huruf
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  // Desain daftar hasil pencarian
  Widget _buildList() {
    final queryLower = query.toLowerCase();

    // Filter data berdasarkan ketikan pengguna (mencari di nama atau deskripsi)
    final matchQuery = features.where((feature) {
      return feature['name'].toLowerCase().contains(queryLower) ||
          feature['desc'].toLowerCase().contains(queryLower);
    }).toList();

    return Container(
      color: const Color(0xFF121212), // Background gelap
      child: ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (context, index) {
          final result = matchQuery[index];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(result['icon'], color: const Color(0xFF00C853)),
            ),
            title: Text(result['name'],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(result['desc'],
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              // Jika ditekan, kembalikan 'action_id' ke layar dashboard
              close(context, result['action']);
            },
          );
        },
      ),
    );
  }
}
