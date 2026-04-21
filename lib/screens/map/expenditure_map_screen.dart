import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
import 'package:intl/intl.dart';

class ExpenditureMapScreen extends StatefulWidget {
  const ExpenditureMapScreen({super.key});

  @override
  State<ExpenditureMapScreen> createState() => _ExpenditureMapScreenState();
}

class _ExpenditureMapScreenState extends State<ExpenditureMapScreen> {
  final FinanceController _financeController = FinanceController();
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];

  bool _isLoading = true;
  String _filterType = 'Semua';
  int? _selectedIndex;

  // [BARU] Variabel untuk melacak bulan yang sedang dilihat
  DateTime _selectedMonth = DateTime.now();
  final List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    setState(() => _isLoading = true);

    // [BARU] Kirimkan bulan dan tahun yang sedang dipilih ke Controller
    final data = await _financeController.getTransactionsWithLocation(
        _selectedMonth.month, _selectedMonth.year);

    setState(() {
      _allData = data;
      _applyFilter(_filterType); // Tetapkan filter yang sedang aktif
      _isLoading = false;
    });
  }

  // [BARU] Fungsi geser bulan
  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
      _selectedIndex = null; // Tutup info card saat pindah bulan
    });
    _loadLocationData();
  }

  void _applyFilter(String type) {
    setState(() {
      _filterType = type;
      _selectedIndex = null;
      if (type == 'Semua') {
        _filteredData = List.from(_allData);
      } else if (type == 'Pemasukan') {
        _filteredData =
            _allData.where((trx) => trx['type'] == 'income').toList();
      } else if (type == 'Pengeluaran') {
        _filteredData =
            _allData.where((trx) => trx['type'] == 'expense').toList();
      }
    });
  }

  void _selectMarker(int index) {
    setState(() => _selectedIndex = index);
    final lat = _filteredData[index]['latitude'] as double;
    final lng = _filteredData[index]['longitude'] as double;
    _mapController.move(LatLng(lat, lng), 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Peta Keuangan",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. LAYER PETA BAWAH
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _filteredData.isNotEmpty
                    ? LatLng(_filteredData[0]['latitude'],
                        _filteredData[0]['longitude'])
                    : const LatLng(-7.7956, 110.3695),
                initialZoom: 13,
                onTap: (_, __) => setState(() => _selectedIndex = null),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),

          // 2. KONTROL ATAS (Bulan, Filter & Legenda)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Kapsul Pilih Bulan
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        "${_namaBulan[_selectedMonth.month - 1]} ${_selectedMonth.year}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 28),
                        // Nonaktifkan panah kanan jika sudah di bulan ini (tidak bisa lihat masa depan)
                        onPressed:
                            (_selectedMonth.month == DateTime.now().month &&
                                    _selectedMonth.year == DateTime.now().year)
                                ? null
                                : () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Baris Filter & Legenda
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterType,
                          dropdownColor: const Color(0xFF2A2A2A),
                          icon: const Icon(Icons.filter_list_rounded,
                              color: Colors.white, size: 18),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                          items: ['Semua', 'Pemasukan', 'Pengeluaran']
                              .map((val) => DropdownMenuItem(
                                  value: val, child: Text(val)))
                              .toList(),
                          onChanged: (val) => _applyFilter(val!),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24)),
                      child: const Row(
                        children: [
                          Icon(Icons.circle,
                              color: Colors.greenAccent, size: 10),
                          SizedBox(width: 4),
                          Text("Masuk",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 12),
                          Icon(Icons.circle, color: Colors.redAccent, size: 10),
                          SizedBox(width: 4),
                          Text("Keluar",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. EFEK LOADING DI TENGAH MAP
          if (_isLoading)
            const Center(
              child: Card(
                color: Color(0xFF1E1E1E),
                shape: CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              ),
            ),

          // 4. INFO CARD BAWAH
          if (!_isLoading && _selectedIndex != null && _filteredData.isNotEmpty)
            _buildBottomInfoCard(),

          // PESAN JIKA DATA KOSONG
          if (!_isLoading && _filteredData.isEmpty)
            const Center(
              child: Card(
                color: Color(0xFF1E1E1E),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text("Tidak ada data lokasi di bulan ini 📭",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    for (int i = 0; i < _filteredData.length; i++) {
      final trx = _filteredData[i];
      final isExpense = trx['type'] == 'expense';
      final isSelected = _selectedIndex == i;

      markers.add(
        Marker(
          point: LatLng(trx['latitude'], trx['longitude']),
          width: isSelected ? 60 : 40,
          height: isSelected ? 60 : 40,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _selectMarker(i),
            child: Icon(
              Icons.location_on_rounded,
              color: isExpense ? Colors.redAccent : Colors.greenAccent,
              size: isSelected ? 50 : 36,
              shadows: [
                Shadow(
                    color: isSelected ? Colors.black87 : Colors.black45,
                    blurRadius: isSelected ? 10 : 4,
                    offset: const Offset(0, 3))
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildBottomInfoCard() {
    final trx = _filteredData[_selectedIndex!];
    final isExpense = trx['type'] == 'expense';

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isExpense
                  ? Colors.redAccent.withOpacity(0.5)
                  : Colors.greenAccent.withOpacity(0.5),
              width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded,
                  color: _selectedIndex! > 0
                      ? Colors.blueAccent
                      : Colors.grey.shade800),
              onPressed: _selectedIndex! > 0
                  ? () => _selectMarker(_selectedIndex! - 1)
                  : null,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(trx['title'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(trx['category'],
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rp ${NumberFormat('#,###').format(trx['amount'])}",
                    style: TextStyle(
                        color:
                            isExpense ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(trx['date'].toString().split(' ')[0],
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10)), // Tanggal Transaksi
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios_rounded,
                  color: _selectedIndex! < _filteredData.length - 1
                      ? Colors.blueAccent
                      : Colors.grey.shade800),
              onPressed: _selectedIndex! < _filteredData.length - 1
                  ? () => _selectMarker(_selectedIndex! + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
