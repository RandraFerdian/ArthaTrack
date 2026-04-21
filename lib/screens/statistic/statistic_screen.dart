import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
import 'package:arthatrack/screens/transaction/transaction_history_screen.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  final FinanceController _financeController = FinanceController();

  bool _isLoading = true;
  double _income = 0.0;
  double _expense = 0.0;
  double _net = 0.0;

  List<MapEntry<String, double>> _categoryDataList = [];
  List<FlSpot> _chartSpots = [];

  DateTime _currentDate = DateTime.now();
  int _touchedIndex = -1;
  String _aiInsight =
      "Tekan tombol di bawah untuk mendapatkan analisis pintar mengenai pengeluaran bulan ini!";
  bool _isFetchingAI = false;

  final Map<String, Color> _categoryColors = {
    'Makanan': Colors.orangeAccent,
    'Transport': Colors.blueAccent,
    'Belanja': Colors.pinkAccent,
    'Hiburan': Colors.purpleAccent,
    'Tagihan': Colors.redAccent,
    'Kesehatan': Colors.tealAccent,
    'Investasi': Colors.greenAccent,
    'Lainnya': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _loadStatisticData();
  }

  Future<void> _loadStatisticData() async {
    setState(() => _isLoading = true);

    final summary = await _financeController.getMonthlySummary(
      _currentDate.month,
      _currentDate.year,
    );
    final categoryData = await _financeController.getExpensesByCategory(
      _currentDate.month,
      _currentDate.year,
    );
    List<Map<String, dynamic>> allTrx = await _financeController
        .getUserTransactions();
    int daysInMonth = DateUtils.getDaysInMonth(
      _currentDate.year,
      _currentDate.month,
    );

    Map<int, double> dailyNet = {for (var i = 1; i <= daysInMonth; i++) i: 0.0};
    for (var trx in allTrx) {
      try {
        DateTime date = DateTime.parse(trx['date']);
        if (date.month == _currentDate.month &&
            date.year == _currentDate.year) {
          double amount = trx['amount'] ?? 0.0;
          if (trx['type'] == 'income') {
            dailyNet[date.day] = dailyNet[date.day]! + amount;
          } else {
            dailyNet[date.day] = dailyNet[date.day]! - amount;
          }
        }
      } catch (e) {}
    }

    List<FlSpot> spots = [];
    double runningTotal = 0.0;
    bool isCurrentMonth =
        _currentDate.month == DateTime.now().month &&
        _currentDate.year == DateTime.now().year;
    int today = DateTime.now().day;

    for (int i = 1; i <= daysInMonth; i++) {
      if (isCurrentMonth && i > today) break;
      runningTotal += dailyNet[i]!;
      spots.add(FlSpot(i.toDouble(), runningTotal));
    }

    // [DIPERBAIKI] Panggilan AI Otomatis Dihapus agar hemat kuota!
    if (mounted) {
      setState(() {
        _income = summary['income'] ?? 0.0;
        _expense = summary['expense'] ?? 0.0;
        _net = summary['net'] ?? 0.0;
        _categoryDataList = categoryData.entries.toList();
        _categoryDataList.sort((a, b) => b.value.compareTo(a.value));
        _chartSpots = spots;
        _isLoading = false;
        _touchedIndex = -1;
      });
    }
  }

  Future<void> _fetchAIInsight() async {
    setState(() => _isFetchingAI = true);
    final insight = await _financeController.getQuickAIInsight('statistic');
    if (mounted) {
      setState(() {
        _aiInsight = insight;
        _isFetchingAI = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + delta, 1);
      _aiInsight =
          "Tekan tombol di bawah untuk mendapatkan analisis pintar mengenai pengeluaran bulan ini!";
    });
    _loadStatisticData();
  }

  String _formatRupiah(double amount) {
    String prefix = amount < 0 ? "- " : "";
    String amountStr = amount.abs().toStringAsFixed(0);
    String formatted = amountStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return "$prefix Rp $formatted";
  }

  @override
  Widget build(BuildContext context) {
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
    String currentMonthName =
        "${monthNames[_currentDate.month - 1]} ${_currentDate.year}";

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Statistik Keuangan",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Fitur Export Laporan PDF segera hadir!"),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C853)),
            )
          : RefreshIndicator(
              onRefresh: _loadStatisticData,
              color: const Color(0xFF00C853),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => _changeMonth(-1),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  currentMonthName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color:
                                _currentDate.month == DateTime.now().month &&
                                    _currentDate.year == DateTime.now().year
                                ? Colors.white24
                                : Colors.white,
                          ),
                          onPressed:
                              _currentDate.month == DateTime.now().month &&
                                  _currentDate.year == DateTime.now().year
                              ? null
                              : () => _changeMonth(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            "Pemasukan",
                            _income,
                            const Color(0xFF00C853),
                            Icons.arrow_downward_rounded,
                            "income",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            "Pengeluaran",
                            _expense,
                            const Color(0xFFFF5252),
                            Icons.arrow_upward_rounded,
                            "expense",
                          ),
                        ),
                      ],
                    ),

                    _buildFinancialStatus(),
                    const SizedBox(height: 32),

                    _buildTrendChart(),
                    const SizedBox(height: 32),

                    _buildArthaInsightCard(), // Kartu AI Insight
                    const SizedBox(height: 32),

                    const Text(
                      "Distribusi Pengeluaran",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _categoryDataList.isEmpty
                        ? Container(
                            height: 200,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              "Belum ada pengeluaran di bulan ini.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 220,
                                  child: PieChart(
                                    PieChartData(
                                      pieTouchData: PieTouchData(
                                        touchCallback:
                                            (
                                              FlTouchEvent event,
                                              pieTouchResponse,
                                            ) {
                                              setState(() {
                                                if (!event
                                                        .isInterestedForInteractions ||
                                                    pieTouchResponse == null ||
                                                    pieTouchResponse
                                                            .touchedSection ==
                                                        null) {
                                                  _touchedIndex = -1;
                                                  return;
                                                }
                                                _touchedIndex = pieTouchResponse
                                                    .touchedSection!
                                                    .touchedSectionIndex;
                                              });
                                            },
                                      ),
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 50,
                                      sections: _buildDonutChartSections(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _touchedIndex == -1
                                          ? Colors.transparent
                                          : _categoryColors[_categoryDataList[_touchedIndex]
                                                    .key]!
                                                .withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _touchedIndex == -1
                                            ? "Total Pengeluaran"
                                            : "Pengeluaran ${_categoryDataList[_touchedIndex].key}",
                                        style: TextStyle(
                                          color: _touchedIndex == -1
                                              ? Colors.grey
                                              : _categoryColors[_categoryDataList[_touchedIndex]
                                                    .key],
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatRupiah(
                                          _touchedIndex == -1
                                              ? _expense
                                              : _categoryDataList[_touchedIndex]
                                                    .value,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ..._categoryDataList
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => _buildLegendItem(
                                        entry.key,
                                        entry.value.key,
                                        entry.value.value,
                                      ),
                                    )
                                    .toList(),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTrendChart() {
    if (_chartSpots.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2962FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF2962FF),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Tren Saldo Harian",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 5,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartSpots,
                    isCurved: true,
                    color: const Color(0xFF2962FF),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2962FF).withOpacity(0.3),
                          const Color(0xFF2962FF).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFF2A2A2A),
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map(
                          (spot) => LineTooltipItem(
                            "Tgl ${spot.x.toInt()}\n${_formatRupiah(spot.y)}",
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialStatus() {
    if (_income == 0 && _expense == 0) return const SizedBox();
    bool isHealthy = _income >= _expense;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHealthy
            ? Colors.green.withOpacity(0.1)
            : Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHealthy
              ? Colors.green.withOpacity(0.3)
              : Colors.redAccent.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: isHealthy ? Colors.green : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isHealthy
                  ? "Keuanganmu bulan ini stabil. Pertahankan!"
                  : "Awas! Pengeluaranmu lebih besar dari pemasukan.",
              style: TextStyle(
                color: isHealthy ? Colors.green : Colors.redAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
    String actionId,
  ) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TransactionHistoryScreen(initialFilter: actionId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _formatRupiah(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArthaInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF311B92).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF651FFF).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF651FFF).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFB388FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Artha AI Insight",
                style: TextStyle(
                  color: Color(0xFFB388FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF651FFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "BETA",
                  style: TextStyle(
                    color: Color(0xFFB388FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _aiInsight,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _isFetchingAI ? null : _fetchAIInsight,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF651FFF).withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isFetchingAI
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
              label: Text(
                _isFetchingAI ? "Menganalisis..." : "✨ Dapatkan Insight",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartSections() {
    if (_expense == 0) return [];
    return _categoryDataList.asMap().entries.map((entry) {
      final int index = entry.key;
      final String category = entry.value.key;
      final double amount = entry.value.value;
      final bool isTouched = index == _touchedIndex;
      final double percentage = (amount / _expense) * 100;
      final Color color = _categoryColors[category] ?? Colors.grey;

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: isTouched ? 55.0 : 45.0,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14.0 : 10.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegendItem(int index, String category, double amount) {
    Color color = _categoryColors[category] ?? Colors.grey;
    bool isTouched = index == _touchedIndex;

    return GestureDetector(
      onTap: () => setState(() => _touchedIndex = isTouched ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isTouched ? 10 : 6),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isTouched ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category,
                style: TextStyle(
                  color: isTouched ? color : Colors.white,
                  fontSize: 14,
                  fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _formatRupiah(amount),
                style: TextStyle(
                  color: isTouched ? color : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
