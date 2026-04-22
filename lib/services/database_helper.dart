import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  // Membuat instance singleton
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Membuka koneksi ke database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('arthatrack.db');
    return _database!;
  }

  // Menentukan lokasi penyimpanan file .db di HP
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Mengeksekusi query pembuatan tabel saat aplikasi pertama kali diinstal
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    // 1. Tabel Users (Mendukung Multi-user & Biometric)
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType UNIQUE,
        password $textType,
        biometric_enabled INTEGER NOT NULL DEFAULT 0,
        bio TEXT DEFAULT 'Belum ada bio',
        profile_image TEXT DEFAULT ''
      )
    ''');

    // 2. Tabel Transactions (Dilengkapi Lat/Long untuk fitur LBS)
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        user_id INTEGER NOT NULL,
        title $textType,
        amount $realType,
        type $textType, 
        category $textType,
        date $textType,
        latitude REAL,
        longitude REAL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabel Savings Goals (Target Tabungan)
    await db.execute('''
      CREATE TABLE savings_goals (
        id $idType,
        user_id INTEGER NOT NULL,
        goal_name $textType,
        target_amount $realType,
        current_amount $realType DEFAULT 0,
        deadline $textType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabel Feedback (Khusus Kriteria Mata Kuliah TPM)
    await db.execute('''
      CREATE TABLE tpm_feedback (
        id $idType,
        user_id INTEGER NOT NULL,
        kesan $textType,
        saran $textType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  //fungsi hashing password menggunakan SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 1. Fungsi Register (Daftar User Baru)
  Future<int> registerUser(String username, String password) async {
    final db = await instance.database;

    final data = {
      'username': username,
      'password': _hashPassword(password), // Simpan versi hash-nya!
      'biometric_enabled': 0, // Default: biometrik belum aktif
    };

    // return nilai id dari user yang baru dibuat
    // conflictAlgorithm.ignore mencegah error jika ada username yang sama
    return await db.insert(
      'users',
      data,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // 2. Fungsi Login (Cek Username & Password)
  Future<Map<String, dynamic>?> loginUser(
    String username,
    String password,
  ) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);

    // Cek apakah ada user dengan username dan password (hash) tersebut
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );

    if (result.isNotEmpty) {
      return result.first; // Login Sukses, kembalikan data user
    } else {
      return null; // Login Gagal (username/password salah)
    }
  }

  // 3. Fungsi Cek Status Biometrik User
  Future<bool> isBiometricEnabled(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      columns: ['biometric_enabled'],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first['biometric_enabled'] == 1;
    }
    return false;
  }

Future<int> updateUserProfile(
      int id, String newUsername, String newBio) async {
    Database db = await instance.database;
    return await db.update(
      'users',
      {
        'username': newUsername,
        'bio': newBio // Memasukkan bio ke database
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateProfileImage(int id, String imagePath) async {
    Database db = await instance.database;
    return await db.update(
      'users',
      {'profile_image': imagePath}, // Memasukkan foto ke database
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // BAGIAN TRANSAKSI (PEMASUKAN & PENGELUARAN)
  // ==========================================
  // 1. Tambah Transaksi Baru (Create)
  Future<int> addTransaction(Map<String, dynamic> transactionData) async {
    final db = await instance.database;
    return await db.insert('transactions', transactionData);
  }

  // 2. Ambil Semua Transaksi Milik 1 User (Read)
  Future<List<Map<String, dynamic>>> getTransactionsByUser(int userId) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  // 3. Hapus Transaksi (Delete)
  Future<int> deleteTransaction(int transactionId) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // 4. Hitung Total Saldo
  Future<double> calculateTotalBalance(int userId) async {
    final db = await instance.database;

    var incomeResult = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE user_id = ? AND type = 'income'",
      [userId],
    );
    // [DIPERBAIKI] Menggunakan .toDouble() agar aman dari error tipe data
    double income = (incomeResult.first['total'] != null)
        ? (incomeResult.first['total'] as num).toDouble()
        : 0.0;

    var expenseResult = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE user_id = ? AND type = 'expense'",
      [userId],
    );
    // [DIPERBAIKI] Menggunakan .toDouble() agar aman
    double expense = (expenseResult.first['total'] != null)
        ? (expenseResult.first['total'] as num).toDouble()
        : 0.0;

    return income - expense;
  }

  // ==========================================
  // BAGIAN TARGET TABUNGAN (SAVINGS GOALS)
  // ==========================================
  // 1. Buat Target Tabungan Baru (Create)
  Future<int> addSavingsGoal(Map<String, dynamic> goalData) async {
    final db = await instance.database;
    return await db.insert('savings_goals', goalData);
  }

  // 2. Ambil Semua Target Tabungan User (Read)
  Future<List<Map<String, dynamic>>> getSavingsGoalsByUser(int userId) async {
    final db = await instance.database;
    return await db.query(
      'savings_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // 3. Tambah Uang ke Target Tabungan (Update Progress)
  Future<int> addMoneyToGoal(int goalId, double amountToAdd) async {
    final db = await instance.database;
    return await db.rawUpdate(
      '''
      UPDATE savings_goals 
      SET current_amount = current_amount + ? 
      WHERE id = ?
    ''',
      [amountToAdd, goalId],
    );
  }

  // 4. Hapus Target Tabungan (Delete)
  Future<int> deleteSavingsGoal(int goalId) async {
    final db = await instance.database;
    return await db.delete(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<int> updateTransaction(
    int id,
    Map<String, dynamic> transactionData,
  ) async {
    Database db = await instance.database; // Ambil koneksi database

    // Melakukan update ke tabel 'transactions' di mana 'id' cocok
    return await db.update(
      'transactions', // Pastikan nama tabel ini sama dengan nama tabel kamu (biasanya 'transactions')
      transactionData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // FUNGSI CRUD TARGET TABUNGAN (SAVINGS GOALS)
  // ==========================================
  Future<int> updateSavingsGoal(int id, Map<String, dynamic> data) async {
    Database db = await instance.database;
    return await db.update(
      'savings_goals',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // [BARU] Mengambil data user berdasarkan ID
  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // [BARU] Memperbarui password user
  Future<int> updatePassword(int userId, String newPassword) async {
    Database db = await instance.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Menutup database jika aplikasi dimatikan
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<int> addFeedback(Map<String, dynamic> feedbackData) async {
    final db = await instance.database;
    return await db.insert('tpm_feedback', feedbackData);
  }

  // 2. Ambil Riwayat Feedback Berdasarkan User ID
  Future<List<Map<String, dynamic>>> getFeedbackByUser(int userId) async {
    final db = await instance.database;
    return await db.query(
      'tpm_feedback',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
  }

  // 3. Update Feedback (U)
  Future<int> updateFeedback(int id, String kesanBaru, String saranBaru) async {
    final db = await instance.database;
    return await db.update(
      'tpm_feedback',
      {'kesan': kesanBaru, 'saran': saranBaru},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 4. Delete Feedback (D)
  Future<int> deleteFeedback(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tpm_feedback',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateBiometricStatus(int userId, bool isEnabled) async {
    Database db = await instance.database;
    return await db.update(
      'users',
      {'biometric_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // [BARU] Mengecek status biometrik berdasarkan username (Untuk Layar Login)
  Future<bool> checkBiometricByUsername(String username) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      columns: ['biometric_enabled'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (res.isNotEmpty) {
      // Mengembalikan true jika biometrik bernilai 1 (On)
      return res.first['biometric_enabled'] == 1;
    }
    return false; // Kembalikan false jika user tidak ditemukan
  }
}
