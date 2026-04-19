import 'package:flutter/material.dart';
import 'package:arthatrack/controllers/currency_controller.dart';

class CurrencyConversionScreen extends StatefulWidget {
  @override
  _CurrencyConversionScreenState createState() =>
      _CurrencyConversionScreenState();
}

class _CurrencyConversionScreenState extends State<CurrencyConversionScreen> {
  final CurrencyController _currencyController = CurrencyController();
  final TextEditingController _amountController = TextEditingController();

  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  double? _resultAmount;
  bool _isLoading = false;

  // Variabel baru untuk menampung data dari API
  bool _isLoadingRates = true;
  List<Map<String, dynamic>> _bankRates = [];

  final List<Map<String, dynamic>> _currencyData = [
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'color': Colors.red},
    {'code': 'USD', 'name': 'US Dollar', 'color': Colors.blue},
    {'code': 'EUR', 'name': 'Euro', 'color': Colors.indigo},
    {'code': 'JPY', 'name': 'Japanese Yen', 'color': Colors.redAccent},
    {'code': 'GBP', 'name': 'British Pound', 'color': Colors.deepPurple},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'color': Colors.yellow},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadBankRates(); // Panggil API saat halaman dibuka
  }

  // Fungsi untuk menarik data dari Frankfurter API
  Future<void> _loadBankRates() async {
    setState(() => _isLoadingRates = true);

    // Kita ingin referensi terhadap IDR dari mata uang utama ini
    List<String> currenciesToCheck = ['USD', 'EUR', 'SGD', 'JPY', 'MYR', 'GBP'];

    final rates = await _currencyController.getBankRates(
      'IDR',
      currenciesToCheck,
    );

    if (mounted) {
      setState(() {
        _bankRates = rates;
        _isLoadingRates = false;
      });
    }
  }

  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _resultAmount = null;
    });
  }

  void _showCurrencyPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
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
              const SizedBox(height: 20),
              const Text(
                "Pilih Mata Uang",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _currencyData.length,
                  itemBuilder: (context, index) {
                    final curr = _currencyData[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: curr['color'].withOpacity(0.2),
                        child: Text(
                          curr['code'][0],
                          style: TextStyle(
                            color: curr['color'],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        curr['code'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        curr['name'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (isFrom)
                            _fromCurrency = curr['code'];
                          else
                            _toCurrency = curr['code'];
                          _resultAmount = null;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleConvert() async {
    if (_amountController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _resultAmount = null;
    });

    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double? result = await _currencyController.convertCurrency(
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
      amount: amount,
    );

    setState(() {
      _isLoading = false;
      _resultAmount = result;
    });
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
          "Kalkulator Kurs",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // --- AREA KALKULATOR UTAMA ---
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: "0.00",
                      hintStyle: TextStyle(color: Colors.white10),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        _buildCurrencyRow(_fromCurrency, true),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Divider(
                                color: Colors.white10,
                                thickness: 1,
                              ),
                              GestureDetector(
                                onTap: _swapCurrencies,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2A2A2A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.swap_vert_rounded,
                                    color: Color(0xFF00C853),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildCurrencyRow(_toCurrency, false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_resultAmount != null)
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00C853).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          "= ${_resultAmount!.toStringAsFixed(2)} $_toCurrency",
                          style: const TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 48),

                  // --- AREA TABEL KURS BANK (REAL-TIME) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Referensi Kurs (IDR)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _isLoadingRates
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.grey,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Live Hari Ini",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Menampilkan Indikator Loading atau List Data
                  if (_isLoadingRates)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF00C853),
                        ),
                      ),
                    )
                  else if (_bankRates.isEmpty)
                    const Center(
                      child: Text(
                        "Gagal mengambil data dari API",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    )
                  else
                    ..._bankRates
                        .map((rateData) => _buildBankRateCard(rateData))
                        .toList(),
                ],
              ),
            ),
          ),

          // --- TOMBOL KONVERSI BAWAH ---
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleConvert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Hitung Konversi",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Pemilih Mata Uang Atas
  Widget _buildCurrencyRow(String code, bool isFrom) {
    final data = _currencyData.firstWhere(
      (e) => e['code'] == code,
      orElse: () => _currencyData[0],
    );
    return InkWell(
      onTap: () => _showCurrencyPicker(isFrom),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: data['color'].withOpacity(0.1),
              child: Text(
                code[0],
                style: TextStyle(
                  color: data['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Widget Kartu Tabel Kurs Bank
  Widget _buildBankRateCard(Map<String, dynamic> data) {
    bool? isUp = data['isUp'];
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.remove_rounded;

    if (isUp == true) {
      statusColor = const Color(0xFF00C853); // Hijau
      statusIcon = Icons.trending_up_rounded;
    } else if (isUp == false) {
      statusColor = const Color(0xFFFF5252); // Merah
      statusIcon = Icons.trending_down_rounded;
    }

    final curr = _currencyData.firstWhere(
      (e) => e['code'] == data['code'],
      orElse: () => _currencyData[0],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: curr['color'].withOpacity(0.15),
            child: Text(
              data['code'][0],
              style: TextStyle(
                color: curr['color'],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "1 ${data['code']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rp ${data['rate'].toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  data['percent'],
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
