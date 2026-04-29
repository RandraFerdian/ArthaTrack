import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
import 'package:arthatrack/controllers/auth_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FinanceController _financeController = FinanceController();
  final AuthController _authController = AuthController();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late ChatSession _chatSession;
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    String? userName = await _authController.getLoggedInUserName();
    double totalBalance = await _financeController.getTotalBalance();
    String financialContext = await _financeController.getAIFinancialContext();
    String balanceStr =
        "Rp ${totalBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
          "Kamu adalah 'Artha AI', asisten dan konsultan keuangan pribadi yang cerdas, asyik, bergaya bahasa anak muda masa kini, analitis, dan suka bicara blak-blakan (candid).\n\n"
          "Klien yang sedang berkonsultasi denganmu adalah: $userName.\n"
          "Total saldo utamanya saat ini adalah: $balanceStr.\n\n"
          "Berikut adalah rekap data keuangannya (Transaksi & Target Tabungan):\n"
          "```\n$financialContext\n```\n\n"
          "TUGAS UTAMAMU SAAT MEMBALAS CHAT PERTAMA:\n"
          "1. Insight Mengejutkan: Jangan mulai dengan sapaan basa-basi biasa. Langsung berikan satu temuan menarik/mengejutkan dari pola pengeluarannya (misal: 'Wah, saldo kamu sisa segini tapi jajan kopinya kenceng juga ya!').\n"
          "2. Analisis Pengeluaran: Evaluasi apakah pengeluarannya wajar dibandingkan dengan total saldonya saat ini.\n"
          "3. Red Flag (Peringatan): Berikan teguran (roasting tipis/halus) jika ada kategori pengeluaran yang terlalu mendominasi.\n"
          "4. Strategi Target: Berikan saran step-by-step yang logis dan realistis agar target tabungannya bisa tercapai sebelum deadline.\n\n"
          "ATURAN JAWABAN:\n"
          "- Gunakan format Markdown (Bullet points, **Bold**) agar rapi dibaca di HP.\n"
          "- Gunakan emoji secukupnya agar chat terasa hidup.\n"
          "- DILARANG MENGARANG DATA. Hanya analisis berdasarkan data context di atas."),
    );

    // 3. Mulai Sesi Chat
    _chatSession = model.startChat();

    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Halo ${userName ?? 'Kak'}! 👋 Aku Artha AI. Aku lihat saldomu saat ini ada **$balanceStr**. Ada yang bisa aku bantu untuk merencanakan keuanganmu hari ini?",
          isUser: false,
        ),
      );
      _isLoading = false;
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Tambahkan pesan user ke UI
    setState(() {
      _messages.add(ChatMessage(text: messageText, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Kirim pesan ke Gemini
      final response = await _chatSession.sendMessage(
        Content.text(messageText),
      );
      final responseText = response.text;

      if (responseText != null) {
        setState(() {
          _messages.add(ChatMessage(text: responseText, isUser: false));
        });
      }
    } catch (e) {
      print("🚨 ERROR Chat AI: $e");
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Maaf, aku sedang mengalami gangguan koneksi nih. Coba lagi nanti ya! 🥺",
            isUser: false,
          ),
        );
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB388FF)),
            const SizedBox(width: 8),
            const Text(
              "Artha AI",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF651FFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "Beta",
                style: TextStyle(
                  color: Color(0xFFB388FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Area Chat List
          Expanded(
            child: _messages.isEmpty && _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB388FF)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildChatBubble(msg);
                    },
                  ),
          ),

          // Indikator Loading AI
          if (_isLoading && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 20,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      color: Color(0xFFB388FF),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Artha sedang mengetik...",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Area Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: "Tanya Artha soal keuanganmu...",
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            _isLoading ? Colors.grey : const Color(0xFF651FFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    bool isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF00C853) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft:
                isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
