import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  double _convertedValue = 0.0;

  bool _isLoadingRates = true;
  List<Map<String, dynamic>> _bankRates = [];

  final List<Map<String, dynamic>> _currencyData = [
    {'code': 'IDR', 'name': 'Indonesia', 'flag': '🇮🇩', 'color': Colors.red},
    {
      'code': 'USD',
      'name': 'United States',
      'flag': '🇺🇸',
      'color': Colors.blue,
    },
    {
      'code': 'EUR',
      'name': 'European Union',
      'flag': '🇪🇺',
      'color': Colors.indigo,
    },
    {'code': 'JPY', 'name': 'Japan', 'flag': '🇯🇵', 'color': Colors.redAccent},
    {
      'code': 'GBP',
      'name': 'United Kingdom',
      'flag': '🇬🇧',
      'color': Colors.deepPurple,
    },
    {'code': 'MYR', 'name': 'Malaysia', 'flag': '🇲🇾', 'color': Colors.yellow},
    {'code': 'SGD', 'name': 'Singapore', 'flag': '🇸🇬', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _loadBankRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    _performInstantConversion();
  }

  Future<void> _loadBankRates() async {
    setState(() => _isLoadingRates = true);
    List<String> currenciesToCheck = ['USD', 'EUR', 'SGD', 'JPY', 'MYR'];
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

  Future<void> _performInstantConversion() async {
    if (_amountController.text.isEmpty) {
      setState(() => _convertedValue = 0.0);
      return;
    }
    // Bersihkan koma sebelum dikirim ke API
    double amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    double? result = await _currencyController.convertCurrency(
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
      amount: amount,
    );
    if (mounted && result != null) {
      setState(() => _convertedValue = result);
    }
  }

  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _performInstantConversion();
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
                      leading: Text(
                        curr['flag'],
                        style: const TextStyle(fontSize: 24),
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
                        });
                        Navigator.pop(context);
                        _performInstantConversion();
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
          "Konversi Valas",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // BOX 1: SOURCE CURRENCY
            _buildCurrencyBox(
              label: "Dari",
              currencyCode: _fromCurrency,
              isInput: true,
              controller: _amountController,
              onTap: () => _showCurrencyPicker(true),
            ),

            // SWAP BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: GestureDetector(
                onTap: _swapCurrencies,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    color: Color(0xFF00C853),
                    size: 28,
                  ),
                ),
              ),
            ),

            // BOX 2: TARGET CURRENCY
            _buildCurrencyBox(
              label: "Ke",
              currencyCode: _toCurrency,
              isInput: false,
              value: _convertedValue,
              onTap: () => _showCurrencyPicker(false),
            ),

            const SizedBox(height: 48),

            // TABLE: PRICE CHANGE PER CENTAGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tabel kurs hari ini",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingRates)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFF00C853)),
                ),
              )
            else
              ..._bankRates.map((rate) => _buildRateRow(rate)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyBox({
    required String label,
    required String currencyCode,
    required bool isInput,
    required VoidCallback onTap,
    TextEditingController? controller,
    double? value,
  }) {
    final curr = _currencyData.firstWhere((e) => e['code'] == currencyCode);
    String formattedOutput = "0.00";
    if (value != null && value > 0) {
      String valStr = value.toStringAsFixed(2);
      List<String> parts = valStr.split('.');
      String formattedInteger = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      formattedOutput =
          parts.length > 1 ? "$formattedInteger.${parts[1]}" : formattedInteger;
    }
    double getDynamicFontSize(String text) {
      int len = text.length;
      if (len <= 10) return 24.0;
      if (len <= 14) return 18.0;
      if (len <= 18) return 14.0;
      return 12.0;
    }

    String textToMeasure = isInput ? (controller?.text ?? "") : formattedOutput;
    double dynamicFontSize = getDynamicFontSize(textToMeasure);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Row(
                    children: [
                      Text(curr['flag'], style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 8),
                      Text(
                        currencyCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: isInput
                      ? TextField(
                          controller: controller,
                          onChanged: (value) {
                            setState(() {});
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                            decimal: false,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          textAlign: TextAlign.right,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: dynamicFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: "0",
                            hintStyle: TextStyle(color: Colors.white10),
                            border: InputBorder.none,
                          ),
                        )
                      // KUNCI 3: Gunakan FittedBox untuk Output, otomatis mengecil dan anti-potong
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            formattedOutput,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(Map<String, dynamic> rate) {
    bool? isUp = rate['isUp'];
    Color statusColor = isUp == true
        ? const Color(0xFF00C853)
        : (isUp == false ? const Color(0xFFFF5252) : Colors.grey);

    final currInfo = _currencyData.firstWhere(
      (e) => e['code'] == rate['code'],
      orElse: () => _currencyData[0],
    );

    // --- LOGIKA FORMAT ANGKA ---
    String rateStr = rate['rate'].toStringAsFixed(2);
    List<String> parts = rateStr.split('.');
    String formattedInteger = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    String finalFormattedRate =
        parts.length > 1 ? "$formattedInteger.${parts[1]}" : formattedInteger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(currInfo['flag'], style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rate['code'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Gunakan variabel yang sudah diformat
                Text(
                  "Rp $finalFormattedRate",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rate['percent'],
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formattedText = cleanText.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
