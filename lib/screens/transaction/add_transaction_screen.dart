import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
import 'package:arthatrack/services/notification_helper.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  final Map<String, dynamic>?
  existingTransaction; // Menyimpan data jika mode edit

  const AddTransactionScreen({
    super.key,
    this.initialType = 'expense',
    this.existingTransaction,
  });

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
  DateTime _selectedDate = DateTime.now(); // Variabel untuk tanggal

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

    // Jika masuk ke Mode Edit, isi form dengan data transaksi lama
    if (widget.existingTransaction != null) {
      _titleController.text = widget.existingTransaction!['title'];
      _selectedCategory = widget.existingTransaction!['category'];
      _selectedType = widget.existingTransaction!['type'];
      try {
        _selectedDate = DateTime.parse(widget.existingTransaction!['date']);
      } catch (e) {}

      // Format angka dengan koma untuk nominal
      String rawAmount = widget.existingTransaction!['amount']
          .toString()
          .replaceAll('.0', '');
      _amountController.text = rawAmount.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
  }

  // Fungsi memunculkan kalender
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00C853),
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: const Color(0xFF121212),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Isi nominal dan catatan dulu, ya!"),
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
      return;
    }

    String cleanAmount = _amountController.text.replaceAll(',', '');
    double amount = double.tryParse(cleanAmount) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nominal harus lebih besar dari Rp 0!"),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    String? error;

    if (widget.existingTransaction == null) {
      // MODE TAMBAH BARU
      error = await _financeController.addTransaction(
        title: _titleController.text,
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        date: _selectedDate.toIso8601String(),
      );
    } else {
      // MODE EDIT
      error = await _financeController.updateTransaction(
        id: widget.existingTransaction!['id'],
        title: _titleController.text,
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        date: _selectedDate.toIso8601String(),
      );
    }

    setState(() => _isLoading = false);

if (error == null) {
      // [BARU] Munculkan Notifikasi Sistem!
      // Ubah tipe bahasa Inggris jadi bahasa Indonesia untuk notif
      String tipeText = _selectedType == 'income' ? 'Pemasukan' : 'Pengeluaran';
      String formattedNominal = "Rp ${NumberFormat('#,###').format(amount)}";

      await NotificationHelper.showTransactionNotification(
        title: "$tipeText Berhasil Dicatat! ✅",
        body:
            "${_titleController.text} sebesar $formattedNominal telah tersimpan.",
      );

      Navigator.pop(context, true); // Kembali dengan state success ke Dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFFF5252),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isIncome = _selectedType == 'income';
    Color activeColor = isIncome
        ? const Color(0xFF00C853)
        : const Color(0xFFFF5252);
    bool isEditMode = widget.existingTransaction != null;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEditMode ? "Edit Transaksi" : "Tambah Transaksi",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
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

                    TextField(
                      controller: _titleController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: "Tambahkan catatan...",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TOMBOL PILIH TANGGAL
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

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
                    ),
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
                      : Text(
                          isEditMode ? "Simpan Perubahan" : "Simpan Transaksi",
                          style: const TextStyle(
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');
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
