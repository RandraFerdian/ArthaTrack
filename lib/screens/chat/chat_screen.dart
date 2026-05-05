import 'package:flutter/material.dart';
import 'package:arthatrack/controllers/chat_controller.dart';
import 'package:arthatrack/screens/chat/chat_widget.dart';
import 'package:arthatrack/src/core/app_colors.dart';
import 'package:arthatrack/src/core/app_font.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController();
    _controller.initializeChat(() => setState(() {}));
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
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    double dynamicBottomPadding = isKeyboardOpen ? 24 : 110;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors
            .transparent, // Dibuat transparan agar menyatu dengan background
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB388FF)),
            const SizedBox(width: 8),
            Text("Artha AI", style: AppFont.h4),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF651FFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("BETA",
                  style: AppFont.overline
                      .copyWith(color: const Color(0xFFB388FF))),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        // Menambahkan background gradient tipis dari gelap ke agak ungu
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Color(0xFF161224)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Area Chat List
            Expanded(
              child: _controller.messages.isEmpty && _controller.isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFB388FF)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: _controller.messages.length,
                      itemBuilder: (context, index) {
                        return ChatBubble(message: _controller.messages[index]);
                      },
                    ),
            ),

            // Indikator Loading AI yang lebih elegan
            if (_controller.isLoading && _controller.messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                color: Color(0xFFB388FF), strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text("Artha sedang mengetik...",
                              style: AppFont.caption
                                  .copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Area Input Box (Floating style)
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, dynamicBottomPadding),
              decoration: BoxDecoration(
                color:
                    AppColors.surface.withOpacity(0.95), 
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5), 
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors
                            .background, // Warna input lebih gelap dari container
                        borderRadius:
                            BorderRadius.circular(30), // Lebih membulat
                        border: Border.all(color: Colors.white10),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: AppFont.bodyMedium,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3, // Bisa ketik multi-line
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: "Tanya Artha soal keuanganmu...",
                          hintStyle: AppFont.bodyMedium
                              .copyWith(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _controller.isLoading
                        ? null
                        : () {
                            _controller.sendMessage(_messageController.text,
                                () => setState(() {}), _scrollToBottom);
                            _messageController.clear();
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _controller.isLoading
                              ? [Colors.grey.shade800, Colors.grey.shade700]
                              : [
                                  const Color(0xFF651FFF),
                                  const Color(0xFFB388FF)
                                ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!_controller.isLoading)
                            BoxShadow(
                              color: const Color(0xFF651FFF).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
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
