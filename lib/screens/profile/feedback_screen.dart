import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arthatrack/services/database_helper.dart'; // Sesuaikan path

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _kesanController = TextEditingController();
  final TextEditingController _saranController = TextEditingController();

  List<Map<String, dynamic>> _feedbackList = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadFeedbackData();
  }

  // --- READ ---
  Future<void> _loadFeedbackData() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId');

    if (_currentUserId != null) {
      final data =
          await DatabaseHelper.instance.getFeedbackByUser(_currentUserId!);
      setState(() {
        _feedbackList = data;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // --- CREATE ---
  Future<void> _submitFeedback() async {
    if (_kesanController.text.trim().isEmpty ||
        _saranController.text.trim().isEmpty) {
      _showSnackBar("Kesan dan Saran tidak boleh kosong!", isError: true);
      return;
    }

    if (_currentUserId != null) {
      await DatabaseHelper.instance.addFeedback({
        'user_id': _currentUserId,
        'kesan': _kesanController.text.trim(),
        'saran': _saranController.text.trim(),
      });

      _kesanController.clear();
      _saranController.clear();
      FocusScope.of(context).unfocus(); // Tutup keyboard

      _showSnackBar("Feedback berhasil dikirim! ✅");
      _loadFeedbackData(); // Refresh list
    }
  }

  // --- DELETE ---
  Future<void> _deleteFeedback(int id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Hapus Feedback?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Feedback ini akan dihapus permanen.",
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("Batal", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.deleteFeedback(id);
              _showSnackBar("Feedback dihapus! 🗑️");
              _loadFeedbackData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Hapus",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- UPDATE (EDIT POP-UP) ---
  void _showEditDialog(Map<String, dynamic> feedback) {
    final TextEditingController editKesan =
        TextEditingController(text: feedback['kesan']);
    final TextEditingController editSaran =
        TextEditingController(text: feedback['saran']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Edit Feedback",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editKesan,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Kesan",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00C853)),
                    borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: editSaran,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Saran",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00C853)),
                    borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("Batal", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              if (editKesan.text.trim().isEmpty ||
                  editSaran.text.trim().isEmpty) {
                _showSnackBar("Kesan dan Saran tidak boleh kosong!",
                    isError: true);
                return;
              }
              Navigator.pop(ctx);
              await DatabaseHelper.instance.updateFeedback(
                  feedback['id'], editKesan.text.trim(), editSaran.text.trim());
              _showSnackBar("Feedback diperbarui! ✨");
              _loadFeedbackData();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2962FF)),
            child: const Text("Simpan",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Evaluasi Proyek TPM",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C853)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FORM CREATE ---
                  const Text("Tulis Feedback Baru",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        TextField(
                          controller: _kesanController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: "Kesan",
                              labelStyle: const TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF00C853)),
                                  borderRadius: BorderRadius.circular(12))),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _saranController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: "Saran",
                              labelStyle: const TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF00C853)),
                                  borderRadius: BorderRadius.circular(12))),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _submitFeedback,
                            icon: const Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                            label: const Text("Kirim Feedback",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2962FF),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text("Riwayat Feedback Anda",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // --- LIST READ, UPDATE, DELETE ---
                  _feedbackList.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Center(
                              child: Text(
                                  "Belum ada feedback yang ditulis.\nTulis feedback pertamamu di atas!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey))),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _feedbackList.length,
                          itemBuilder: (context, index) {
                            final feedback = _feedbackList[index];
                            return Card(
                              color: const Color(0xFF1E1E1E),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Bagian Teks Feedback
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            color: Colors.amber, size: 16),
                                        const SizedBox(width: 8),
                                        const Text("Kesan:",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(feedback['kesan'] ?? "-",
                                        style: const TextStyle(
                                            color: Colors.white)),

                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8),
                                        child: Divider(color: Colors.white10)),

                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.lightbulb_outline_rounded,
                                            color: Colors.cyanAccent,
                                            size: 16),
                                        const SizedBox(width: 8),
                                        const Text("Saran:",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(feedback['saran'] ?? "-",
                                        style: const TextStyle(
                                            color: Colors.white)),

                                    // --- TOMBOL EDIT & DELETE ---
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              _showEditDialog(feedback),
                                          icon: const Icon(Icons.edit_rounded,
                                              color: Colors.blueAccent,
                                              size: 16),
                                          label: const Text("Edit",
                                              style: TextStyle(
                                                  color: Colors.blueAccent,
                                                  fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _deleteFeedback(feedback['id']),
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.redAccent,
                                              size: 16),
                                          label: const Text("Hapus",
                                              style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 12)),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
