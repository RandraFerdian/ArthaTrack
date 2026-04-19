import 'package:flutter/material.dart';
import 'package:arthatrack/controllers/finance_controller.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;

  const AddTransactionScreen({super.key, this.initialType = 'expense'});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final FinanceController _financeController = FinanceController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late String _selectedType;
  String _selectedCategory = 'Makanan';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Makanan', 'icon': Icons.fastfood_rounded},
    {'name': 'Transport', 'icon': Icons.directions_car_rounded},
    {'name': 'Belanja', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Hiburan', 'icon': Icons.confirmation_number_rounded},
    {'name': 'Gaji', 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'Tagihan', 'icon': Icons.receipt_long_rounded},
    {'name': 'Kesehatan', 'icon': Icons.medical_services_rounded},
    {'name': 'Investasi', 'icon': Icons.trending_up_rounded},
    {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Isi nominal dan catatan dulu, ya!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    String? error = await _financeController.addTransaction(
      title: _titleController.text,
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
    );
    setState(() => _isLoading = false);
    if (error == null) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isIncome = _selectedType == 'income';
    Color activeColor = isIncome
        ? const Color(0xFF00C853)
        : const Color(0xFFFF5252);

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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. TOGGLE SWITCH PREMIUM (Pill-shape)
                      Container(
                        height: 50,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            _buildToggleTab("income", "Pemasukan"),
                            _buildToggleTab("expense", "Pengeluaran"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 2. INPUT NOMINAL CLEAN (Tanpa kotak)
                      const Text(
                        "Nominal Transaksi",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        cursorColor: activeColor,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: "0",
                          hintStyle: TextStyle(color: Colors.white24),
                          prefixText: "Rp ",
                          prefixStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 3. INPUT CATATAN (Sleek minimalist line)
                      TextField(
                        controller: _titleController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Tambahkan catatan...",
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 4. KATEGORI (Ikon Sirkular Eksklusif)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Kategori",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 20,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: _categories.map((cat) {
                          bool isSelected = _selectedCategory == cat['name'];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat['name']),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              width: 75,
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? activeColor.withOpacity(0.15)
                                          : const Color(0xFF1E1E1E),
                                      border: Border.all(
                                        color: isSelected
                                            ? activeColor
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      cat['icon'],
                                      color: isSelected
                                          ? activeColor
                                          : Colors.grey,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cat['name'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white54,
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // 5. TOMBOL SIMPAN (Mengambang di bawah)
            Container(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 32,
                top: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF121212),
                    const Color(0xFF121212).withOpacity(0.0),
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ), // Pill-shape full
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Simpan Transaksi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTab(String type, String title) {
    bool isSelected = _selectedType == type;
    Color activeColor = type == 'income'
        ? const Color(0xFF00C853)
        : const Color(0xFFFF5252);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2A2A2A) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? activeColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
