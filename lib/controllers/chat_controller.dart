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
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: _apiKey,
      systemInstruction: Content.system(
          "Kamu adalah 'Artha AI', asisten keuangan dan finansial pribadi yang objektif, logis, dan santai.\n\n"
          "User: $userName | Saldo: $balanceStr\n"
          "Data Keuangan:\n```\n$financialContext\n```\n\n"
          "ATURAN SUPER KETAT (WAJIB DIPATUHI):\n"
          "1. DOMAIN FINANSIAL: Kamu HANYA boleh merespons pertanyaan seputar keuangan, penghematan, investasi (saham, kripto, reksa dana), budgeting, dan analisis pengeluaran.\n"
          "2. TOLAK TOPIK DI LUAR KONTEKS: Jika user bertanya tentang programming, matematika umum, sejarah, atau apa pun di luar uang, KAMU WAJIB MENOLAKNYA. \n"
          "   - Format Penolakan: 'Maaf ya, Artha ini asisten keuangan. Kalau urusan [sebutkan topik yang ditanya user], Artha angkat tangan deh! Ada yang mau diobrolin soal saldo atau target tabunganmu?'\n"
          "3. TONE: Realistis, logis, santai. Hindari motivasi kosong.\n"
          "4. BATASAN DATA: Gunakan data saldo dan riwayat di atas untuk urusan personal."
          "5. Format: Markdown (Bullet, **Bold**), emoji minim."),
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
