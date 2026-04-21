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

  final List<Map<String, dynamic>> _questions = [
    {
      'flag': '🇯🇵',
      'question': 'Mata uang negara Jepang adalah?',
      'options': ['Won', 'Yen', 'Yuan', 'Baht'],
      'answer': 'Yen',
    },
    {
      'flag': '🇬🇧',
      'question': 'Simbol £ adalah untuk mata uang?',
      'options': ['Pound', 'Euro', 'Dollar', 'Franc'],
      'answer': 'Pound',
    },
    {
      'flag': '🇰🇷',
      'question': 'Mata uang Won (₩) berasal dari?',
      'options': ['Korsel', 'China', 'Jepang', 'Vietnam'],
      'answer': 'Korsel',
    },
    {
      'flag': '🇪🇺',
      'question': 'Mata uang resmi Uni Eropa adalah?',
      'options': ['Pound', 'Franc', 'Euro', 'Krone'],
      'answer': 'Euro',
    },
    {
      'flag': '🇸🇦',
      'question': 'Negara Arab Saudi menggunakan?',
      'options': ['Dinar', 'Dirham', 'Riyal', 'Rupee'],
      'answer': 'Riyal',
    },
  ];

  void _checkAnswer() {
    if (_selectedOption.isEmpty) return;

    setState(() {
      _hasChecked = true;
      _isCorrect = _selectedOption == _questions[_currentIndex]['answer'];
      if (_isCorrect) _score += 20;
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
        _selectedOption = "";
        _hasChecked = false;
        _isCorrect = false;
      } else {
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00C853), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🎯", style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text(
                "Misi Selesai!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Skor Kamu: $_score",
                style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
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
    final currentQ = _questions[_currentIndex];
    double progress = (_currentIndex) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER BAR ALA DUOLINGO (Close, Progress, Hearts)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress == 0
                            ? 0.05
                            : progress, // Agar terlihat ada sedikit isi di awal
                        backgroundColor: const Color(0xFF2A2A2A),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00C853),
                        ),
                        minHeight: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // KONTEN PERTANYAAN
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
                        fontWeight: FontWeight.bold,
                      ),
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
                        fontWeight: FontWeight.w600,
                      ),
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
                              // Efek tombol 3D
                              boxShadow: isSelected
                                  ? []
                                  : [
                                      const BoxShadow(
                                        color: Color(0xFF0A0A0A),
                                        offset: Offset(0, 4),
                                      ),
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
                        Text(
                          _isCorrect
                              ? "Luar biasa!"
                              : "Jawaban yang benar:\n${currentQ['answer']}",
                          style: TextStyle(
                            color: _isCorrect
                                ? const Color(0xFF00C853)
                                : Colors.redAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _selectedOption.isEmpty && !_hasChecked
                            ? 0
                            : 4,
                      ),
                      onPressed: _hasChecked ? _nextQuestion : _checkAnswer,
                      child: Text(
                        _hasChecked ? "LANJUT" : "CEK",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
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
