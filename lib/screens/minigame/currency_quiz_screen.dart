import 'dart:math';
import 'package:flutter/material.dart';

class CurrencyQuizScreen extends StatefulWidget {
  const CurrencyQuizScreen({super.key});

  @override
  State<CurrencyQuizScreen> createState() => _CurrencyQuizScreenState();
}

class _CurrencyQuizScreenState extends State<CurrencyQuizScreen> {
  int _currentIndex = 0;
  int _score = 0;

  String _selectedOption = "";
  bool _hasChecked = false;
  bool _isCorrect = false;

  // List soal aktif (hanya berisi 5 soal yang terpilih)
  List<Map<String, dynamic>> _activeQuestions = [];

  // Bank Soal Utama (20 Soal)
  final List<Map<String, dynamic>> _masterQuestions = [
    {
      'flag': '🇯🇵',
      'question': 'Mata uang negara Jepang adalah?',
      'options': ['Won', 'Yen', 'Yuan', 'Baht'],
      'answer': 'Yen'
    },
    {
      'flag': '🇰🇷',
      'question': 'Mata uang negara Korea Selatan adalah?',
      'options': ['Krone', 'Yen', 'Won', 'Ringgit'],
      'answer': 'Won'
    },
    {
      'flag': '🇪🇺',
      'question': 'Mata uang resmi Uni Eropa adalah?',
      'options': ['Pound', 'Franc', 'Euro', 'Dollar'],
      'answer': 'Euro'
    },
    {
      'flag': '🇸🇦',
      'question': 'Negara Arab Saudi menggunakan?',
      'options': ['Dinar', 'Dirham', 'Riyal', 'Rupee'],
      'answer': 'Riyal'
    },
    {
      'flag': '🇺🇸',
      'question': 'Mata uang negara Amerika Serikat adalah?',
      'options': ['Pound', 'Euro', 'Dollar', 'Real'],
      'answer': 'Dollar'
    },
    {
      'flag': '🇬🇧',
      'question': 'Inggris Raya (UK) menggunakan mata uang?',
      'options': ['Euro', 'Pound Sterling', 'Franc', 'Krone'],
      'answer': 'Pound Sterling'
    },
    {
      'flag': '🇨🇳',
      'question': 'Mata uang negara China adalah?',
      'options': ['Yen', 'Won', 'Yuan', 'Baht'],
      'answer': 'Yuan'
    },
    {
      'flag': '🇮🇳',
      'question': 'Mata uang negara India adalah?',
      'options': ['Rupee', 'Rupiah', 'Riyal', 'Rand'],
      'answer': 'Rupee'
    },
    {
      'flag': '🇲🇾',
      'question': 'Negara Malaysia menggunakan mata uang?',
      'options': ['Rupiah', 'Ringgit', 'Baht', 'Peso'],
      'answer': 'Ringgit'
    },
    {
      'flag': '🇸🇬',
      'question': 'Mata uang Singapura adalah?',
      'options': ['Dollar', 'Ringgit', 'Yuan', 'Baht'],
      'answer': 'Dollar'
    },
    {
      'flag': '🇹🇭',
      'question': 'Mata uang negara Thailand adalah?',
      'options': ['Dong', 'Kyat', 'Baht', 'Riel'],
      'answer': 'Baht'
    },
    {
      'flag': '🇻🇳',
      'question': 'Vietnam menggunakan mata uang?',
      'options': ['Dong', 'Baht', 'Won', 'Kip'],
      'answer': 'Dong'
    },
    {
      'flag': '🇵🇭',
      'question': 'Mata uang negara Filipina adalah?',
      'options': ['Peso', 'Real', 'Dollar', 'Baht'],
      'answer': 'Peso'
    },
    {
      'flag': '🇦🇺',
      'question': 'Australia menggunakan mata uang?',
      'options': ['Pound', 'Dollar', 'Euro', 'Franc'],
      'answer': 'Dollar'
    },
    {
      'flag': '🇷🇺',
      'question': 'Mata uang negara Rusia adalah?',
      'options': ['Krone', 'Rubel', 'Lira', 'Zloty'],
      'answer': 'Rubel'
    },
    {
      'flag': '🇿🇦',
      'question': 'Afrika Selatan menggunakan mata uang?',
      'options': ['Rand', 'Pound', 'Dinar', 'Rupee'],
      'answer': 'Rand'
    },
    {
      'flag': '🇧🇷',
      'question': 'Mata uang negara Brasil adalah?',
      'options': ['Peso', 'Real', 'Dollar', 'Sol'],
      'answer': 'Real'
    },
    {
      'flag': '🇲🇽',
      'question': 'Mata uang negara Meksiko adalah?',
      'options': ['Real', 'Bolivar', 'Peso', 'Dollar'],
      'answer': 'Peso'
    },
    {
      'flag': '🇨🇭',
      'question': 'Swiss (Switzerland) menggunakan?',
      'options': ['Euro', 'Franc', 'Krone', 'Pound'],
      'answer': 'Franc'
    },
    {
      'flag': '🇦🇪',
      'question': 'Mata uang Uni Emirat Arab (Dubai) adalah?',
      'options': ['Riyal', 'Dinar', 'Dirham', 'Pound'],
      'answer': 'Dirham'
    },
  ];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    final random = Random();
    List<Map<String, dynamic>> shuffled = List.from(_masterQuestions);
    shuffled.shuffle(random);

    setState(() {
      _activeQuestions = shuffled.take(5).toList();
      _currentIndex = 0;
      _score = 0;
      _selectedOption = "";
      _hasChecked = false;
      _isCorrect = false;
    });
  }

  void _checkAnswer() {
    if (_selectedOption.isEmpty) return;

    setState(() {
      _hasChecked = true;
      _isCorrect = _selectedOption == _activeQuestions[_currentIndex]['answer'];
      if (_isCorrect) _score += 20;
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentIndex < _activeQuestions.length - 1) {
        _currentIndex++;
        _selectedOption = "";
        _hasChecked = false;
        _isCorrect = false;
      } else {
        _showResultDialog();
      }
    });
  }

  // =====================================================================
  // UI DIALOG HASIL GAME YANG SUDAH DIPERBAIKI MENJADI SANGAT ELEGAN
  // =====================================================================
  void _showResultDialog() {
    String emoji = "💪";
    String pesan = "Tetap Semangat!";
    Color warnaSkor = Colors.orangeAccent;

    // Logika Dinamis untuk tampilan berdasar skor
    if (_score == 100) {
      emoji = "🏆";
      pesan = "Sempurna!";
      warnaSkor = const Color(0xFF00C853); // Hijau
    } else if (_score >= 60) {
      emoji = "🌟";
      pesan = "Kerja Bagus!";
      warnaSkor = Colors.blueAccent; // Biru
    } else {
      emoji = "😅";
      pesan = "Coba Lagi Yuk!";
      warnaSkor = Colors.redAccent; // Merah
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: warnaSkor.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: warnaSkor.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 70)),
              const SizedBox(height: 16),
              Text(
                pesan,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Skor Akhir Kamu",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),

              // KOTAK SKOR
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: warnaSkor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$_score / 100",
                  style: TextStyle(
                    color: warnaSkor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // TOMBOL MAIN LAGI (ELEVATED)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warnaSkor,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: warnaSkor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startNewGame();
                  },
                  child: const Text(
                    "MAIN LAGI",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // TOMBOL KEMBALI (OUTLINE)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "KEMBALI KE DASHBOARD",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
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
    if (_activeQuestions.isEmpty) return const SizedBox();

    final currentQ = _activeQuestions[_currentIndex];
    double progress = (_currentIndex) / _activeQuestions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.grey, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress == 0 ? 0.05 : progress,
                        backgroundColor: const Color(0xFF2A2A2A),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00C853)),
                        minHeight: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Pilih jawaban yang tepat!",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),

                    Center(
                      child: Text(
                        currentQ['flag'],
                        style: const TextStyle(fontSize: 100),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      currentQ['question'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 40),

                    // GRID JAWABAN
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: currentQ['options'].length,
                      itemBuilder: (context, index) {
                        String option = currentQ['options'][index];
                        bool isSelected = _selectedOption == option;

                        return GestureDetector(
                          onTap: _hasChecked
                              ? null
                              : () => setState(() => _selectedOption = option),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.indigoAccent.withOpacity(0.2)
                                  : const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.indigoAccent
                                    : const Color(0xFF2A2A2A),
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: isSelected
                                  ? []
                                  : [
                                      const BoxShadow(
                                          color: Color(0xFF0A0A0A),
                                          offset: Offset(0, 4)),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                option,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.indigoAccent
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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

            // AREA BAWAH (TOMBOL CEK & FEEDBACK)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _hasChecked
                    ? (_isCorrect
                        ? const Color(0xFF00C853).withOpacity(0.15)
                        : Colors.redAccent.withOpacity(0.15))
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasChecked) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isCorrect
                                ? const Color(0xFF00C853)
                                : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isCorrect
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          // Dibungkus agar text panjang tidak error
                          child: Text(
                            _isCorrect
                                ? "Luar biasa!"
                                : "Jawaban benar: ${currentQ['answer']}",
                            style: TextStyle(
                              color: _isCorrect
                                  ? const Color(0xFF00C853)
                                  : Colors.redAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChecked
                            ? (_isCorrect
                                ? const Color(0xFF00C853)
                                : Colors.redAccent)
                            : (_selectedOption.isEmpty
                                ? const Color(0xFF2A2A2A)
                                : Colors.indigoAccent),
                        foregroundColor: _selectedOption.isEmpty && !_hasChecked
                            ? Colors.grey
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation:
                            _selectedOption.isEmpty && !_hasChecked ? 0 : 4,
                      ),
                      onPressed: (_selectedOption.isEmpty && !_hasChecked)
                          ? null
                          : (_hasChecked ? _nextQuestion : _checkAnswer),
                      child: Text(
                        _hasChecked ? "LANJUT" : "CEK",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
