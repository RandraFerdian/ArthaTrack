import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimeConversionScreen extends StatefulWidget {
  const TimeConversionScreen({super.key});

  @override
  State<TimeConversionScreen> createState() => _TimeConversionScreenState();
}

class _TimeConversionScreenState extends State<TimeConversionScreen> {
  bool _isTimezoneInitialized = false;
  String _fromZone = "WIB (Jakarta)";
  String _toZone = "London (UK)";
  TimeOfDay _selectedTime = TimeOfDay.now();

  final Map<String, String> _timezoneLocations = {
    "WIB (Jakarta)": "Asia/Jakarta",
    "WITA (Makassar)": "Asia/Makassar",
    "WIT (Jayapura)": "Asia/Jayapura",
    "London (UK)": "Europe/London",
    "New York (US)": "America/New_York",
    "Tokyo (Jepang)": "Asia/Tokyo",
    "Singapore": "Asia/Singapore",
    "Makkah (Arab Saudi)":
        "Asia/Riyadh", 
    "Sydney (Australia)": "Australia/Sydney",
  };

  @override
  void initState() {
    super.initState();
    _setupTimezones();
  }

  // Fungsi untuk menginisialisasi database waktu dunia
  Future<void> _setupTimezones() async {
    tz.initializeTimeZones();
    setState(() {
      _isTimezoneInitialized = true;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // LOGIKA BARU: Menghitung dengan library timezone
  Map<String, String> _getConvertedTime() {
    if (!_isTimezoneInitialized) {
      return {"time": "--:--", "day": "Loading..."};
    }

    // 1. Ambil lokasi zona waktu
    final fromLocation = tz.getLocation(_timezoneLocations[_fromZone]!);
    final toLocation = tz.getLocation(_timezoneLocations[_toZone]!);

    // 2. Buat objek waktu asal (berdasarkan tanggal hari ini di zona asal)
    final nowInFromZone = tz.TZDateTime.now(fromLocation);
    final fromTime = tz.TZDateTime(
      fromLocation,
      nowInFromZone.year,
      nowInFromZone.month,
      nowInFromZone.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // 3. Konversi ke zona waktu tujuan
    final toTime = tz.TZDateTime.from(fromTime, toLocation);

    // 4. Hitung perbedaan hari (dengan murni membandingkan tanggal kalender)
    DateTime fromDate =
        DateTime.utc(fromTime.year, fromTime.month, fromTime.day);
    DateTime toDate = DateTime.utc(toTime.year, toTime.month, toTime.day);
    int dayDiff = toDate.difference(fromDate).inDays;

    String dayIndicator = "";
    if (dayDiff > 0) {
      dayIndicator = "(Hari Berikutnya)";
    } else if (dayDiff < 0) {
      dayIndicator = "(Hari Sebelumnya)";
    } else {
      dayIndicator = "(Hari yang Sama)";
    }

    return {
      "time": DateFormat('HH:mm').format(toTime),
      "day": dayIndicator,
    };
  }

  @override
  Widget build(BuildContext context) {
    final convertedData = _getConvertedTime();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Konversi Waktu",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
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
      body: !_isTimezoneInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. KARTU INPUT & KONVERSI ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimezoneDropdown(
                                "Dari",
                                _fromZone,
                                (val) => setState(() => _fromZone = val!),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(
                                Icons.compare_arrows_rounded,
                                color: Colors.blueAccent,
                                size: 28,
                              ),
                            ),
                            Expanded(
                              child: _buildTimezoneDropdown(
                                "Ke",
                                _toZone,
                                (val) => setState(() => _toZone = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Jam Asal (Pilih)",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedTime.format(context),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.blueAccent,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 2. KARTU HASIL ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade900.withOpacity(0.4),
                          const Color(0xFF1E1E1E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Jam di $_toZone:",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          convertedData["time"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            convertedData["day"]!,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- 3. LIST WAKTU DUNIA SAAT INI ---
                  const Text(
                    "Waktu Dunia Saat Ini",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._timezoneLocations.entries.map((entry) {
                    // Menghitung jam saat ini secara presisi dengan library timezone
                    final loc = tz.getLocation(entry.value);
                    final cityTime = tz.TZDateTime.now(loc);

                    String formattedTime = DateFormat('HH:mm').format(cityTime);
                    String formattedDate =
                        DateFormat('dd MMM').format(cityTime);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.public_rounded,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildTimezoneDropdown(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                color: Colors.blueAccent,
              ),
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              items: _timezoneLocations.keys.map((String key) {
                return DropdownMenuItem<String>(
                  value: key,
                  child: Text(key, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
