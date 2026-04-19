import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyController {
  // Menggunakan Frankfurter API (Tanpa API Key, Open Source)
  final String _baseUrl = "https://api.frankfurter.app";

  // 1. FUNGSI KONVERSI CEPAT (Untuk Kalkulator)
  Future<double?> convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    if (fromCurrency == toCurrency) return amount;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/latest?from=$fromCurrency&to=$toCurrency'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double rate = (data['rates'][toCurrency] as num).toDouble();
        return amount * rate;
      }
    } catch (e) {
      print("Error konversi kurs: $e");
    }
    return null;
  }

  // 2. FUNGSI PAPAN KURS BANK (Dengan Indikator Naik/Turun)
  Future<List<Map<String, dynamic>>> getBankRates(
    String targetCurrency,
    List<String> currenciesToCheck,
  ) async {
    List<Map<String, dynamic>> results = [];

    // Ambil data dari 7 hari lalu sampai hari ini (untuk bypass hari libur Sabtu/Minggu dimana pasar forex tutup)
    DateTime today = DateTime.now();
    DateTime lastWeek = today.subtract(const Duration(days: 7));

    String endDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    String startDate =
        "${lastWeek.year}-${lastWeek.month.toString().padLeft(2, '0')}-${lastWeek.day.toString().padLeft(2, '0')}";

    try {
      // Ambil data time-series
      final response = await http.get(
        Uri.parse('$_baseUrl/$startDate..$endDate'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Map<String, dynamic> ratesByDate = data['rates'];

        // Ambil daftar tanggal yang dikembalikan API (sudah terurut dari terlama ke terbaru)
        List<String> availableDates = ratesByDate.keys.toList();

        if (availableDates.length >= 2) {
          String latestDate = availableDates.last; // Harga Hari ini / Terakhir
          String previousDate =
              availableDates[availableDates.length - 2]; // Harga Kemarin

          Map<String, dynamic> latestRates = ratesByDate[latestDate];
          Map<String, dynamic> prevRates = ratesByDate[previousDate];

          // Karena Base default adalah EUR, kita gunakan metode Cross-Rate
          double latestTargetRate = targetCurrency == 'EUR'
              ? 1.0
              : (latestRates[targetCurrency] ?? 1.0).toDouble();
          double prevTargetRate = targetCurrency == 'EUR'
              ? 1.0
              : (prevRates[targetCurrency] ?? 1.0).toDouble();

          for (String code in currenciesToCheck) {
            if (code == targetCurrency) continue;

            double latestCodeRate = code == 'EUR'
                ? 1.0
                : (latestRates[code] ?? 1.0).toDouble();
            double prevCodeRate = code == 'EUR'
                ? 1.0
                : (prevRates[code] ?? 1.0).toDouble();

            // Hitung harga terhadap target (misal: USD ke IDR)
            double currentPrice = latestTargetRate / latestCodeRate;
            double previousPrice = prevTargetRate / prevCodeRate;

            // Hitung kenaikan/penurunan (Delta)
            double delta = currentPrice - previousPrice;
            double percent = (delta / previousPrice) * 100;
            bool? isUp = delta > 0;
            if (delta == 0) isUp = null; // Harga stabil

            results.add({
              'code': code,
              'rate': currentPrice,
              'delta': delta,
              'isUp': isUp,
              'percent':
                  '${delta > 0 ? '+' : ''}${percent.toStringAsFixed(2)}%',
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching bank rates: $e");
    }
    return results;
  }
}
