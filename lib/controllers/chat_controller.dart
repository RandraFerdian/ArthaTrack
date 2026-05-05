import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:arthatrack/controllers/finance_controller.dart';
import 'package:arthatrack/controllers/auth_controller.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatController {
  final FinanceController _financeController = FinanceController();
  final AuthController _authController = AuthController();

  List<ChatMessage> messages = [];
  bool isLoading = false;
  late ChatSession _chatSession;
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<void> initializeChat(Function updateUI) async {
    isLoading = true;
    updateUI();

    String? userName = await _authController.getLoggedInUserName();
    double totalBalance = await _financeController.getTotalBalance();
    String financialContext = await _financeController.getAIFinancialContext();
    String balanceStr =
        "Rp ${totalBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
          "Kamu 'Artha AI', teman ngobrol finansial yang objektif, logis, dan santai (tidak menggurui/lebay).\n\n"
          "User: $userName | Saldo: $balanceStr\n"
          "Data Keuangan:\n```\n$financialContext\n```\n\n"
          "ATURAN:\n"
          "1. Peran: Beri saran praktis & actionable soal personal finance sesuai data user. Untuk topik market/umum, pakai analogi sederhana dan kaitkan dengan kondisi dompet user.\n"
          "2. Tone: Realistis. Hindari motivasi kosong/klise.\n"
          "3. Batasan: MUTLAK gunakan data di atas untuk urusan personal (dilarang mengarang). Gunakan wawasanmu murni untuk menjawab pertanyaan umum/teori.\n"
          "4. Format: Markdown (Bullet, **Bold**), emoji minim."),
    );

    _chatSession = model.startChat();

    messages.add(
      ChatMessage(
        text:
            "Halo ${userName ?? 'Kak'}! 👋 Aku Artha AI. Aku lihat saldomu saat ini ada **$balanceStr**. Ada yang bisa aku bantu untuk merencanakan keuanganmu hari ini?",
        isUser: false,
      ),
    );

    isLoading = false;
    updateUI();
  }

  Future<void> sendMessage(
      String messageText, Function updateUI, Function scrollToBottom) async {
    if (messageText.trim().isEmpty) return;

    messages.add(ChatMessage(text: messageText, isUser: true));
    isLoading = true;
    updateUI();
    scrollToBottom();

    try {
      final response =
          await _chatSession.sendMessage(Content.text(messageText));
      if (response.text != null) {
        messages.add(ChatMessage(text: response.text!, isUser: false));
      }
    } catch (e) {
      print("🚨 ERROR Chat AI: $e");
      messages.add(
        ChatMessage(
          text:
              "Maaf, aku sedang mengalami gangguan koneksi nih. Coba lagi nanti ya! 🥺",
          isUser: false,
        ),
      );
    } finally {
      isLoading = false;
      updateUI();
      scrollToBottom();
    }
  }
}
