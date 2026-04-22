# 💸 ArthaTrack: AI-Powered Personal Finance

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![Gemini API](https://img.shields.io/badge/Gemini%20API-8E75B2.svg?style=for-the-badge&logo=Google-Bard&logoColor=white)](https://aistudio.google.com/)

**ArthaTrack** adalah aplikasi pelacak keuangan pribadi cerdas berbasis mobile yang dikembangkan menggunakan Flutter. Tidak hanya mencatat angka, ArthaTrack bertindak sebagai asisten finansial pribadi Anda dengan memadukan interaksi sensor perangkat, keamanan biometrik, dan kecerdasan buatan (AI) dari Google Gemini.

---

## ✨ Fitur Unggulan

* 🤖 **AI Financial Advisor:** Asisten chat pintar berbasis **Gemini AI** yang siap memberikan saran keuangan, analisis pengeluaran, dan tips menabung secara *real-time*.
* 🔒 **Keamanan Biometrik Lanjutan:** Akses aplikasi dengan aman dan cepat menggunakan pemindai sidik jari (*Fingerprint*) bawaan perangkat.
* 📳 **Interaksi Berbasis Sensor:** * **Tilt to Navigate (Gyroscope):** Berpindah menu hanya dengan memiringkan *smartphone* ke kiri atau kanan.
    * **Shake to Sync (Accelerometer):** Goyangkan ponsel untuk memuat ulang dan menyinkronkan data transaksi dengan efek animasi yang mulus.
* ⏰ **Pengingat Pintar (Daily Reminder):** Notifikasi lokal otomatis yang mengingatkan Anda setiap hari agar tidak ada pengeluaran yang terlewat.
* 💾 **Offline-First Database:** Kinerja super cepat tanpa *lag* karena semua data, foto profil, dan pengaturan disimpan secara lokal menggunakan **SQLite**.
* 📊 **Analisis Visual & Target:** Pantau arus kas melalui grafik interaktif dan kelola tabungan untuk mencapai *goals* finansial Anda.

---

## 🛠️ Teknologi & Library Utama

Aplikasi ini dibangun menggunakan arsitektur modern dan *library* unggulan Flutter:

* `sqflite` - Manajemen relasional Database lokal.
* `flutter_dotenv` - Mengamankan *API Keys* dan konfigurasi *environment*.
* `google_generative_ai` - Integrasi *seamless* dengan model AI Gemini.
* `flutter_local_notifications` - Penjadwalan alarm dan notifikasi sistem.
* `sensors_plus` - Akses *hardware* Accelerometer dan Gyroscope.
* `local_auth` - Autentikasi biometrik sistem operasi.

---

## 🚀 Panduan Instalasi & Menjalankan Project

Ikuti langkah-langkah berikut untuk menjalankan ArthaTrack di komputer lokal Anda.

### 1. Prasyarat Sistem
Pastikan Anda sudah menginstal:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Versi terbaru yang direkomendasikan)
* Code Editor (VS Code atau Android Studio)
* Perangkat fisik (*Smartphone*) atau Emulator untuk mencoba fitur sensor dan biometrik.

### 2. Kloning & Unduh Dependencies
Buka terminal Anda dan jalankan perintah berikut:
```bash
# 1. Kloning repositori
git clone [https://github.com/RandraFerdian/arthatrack.git](https://github.com/RandraFerdian/arthatrack.git)

# 2. Masuk ke direktori aplikasi
cd arthatrack

# 3. Unduh semua package yang dibutuhkan
flutter pub get
```

### 3. Konfigurasi Environment (.env) 🔑
Aplikasi ini membutuhkan akses ke **Gemini API** untuk fitur AI Chat. Demi keamanan, API Key tidak disertakan dalam *source code*. Anda harus mengaturnya secara manual:

1. Dapatkan API Key secara gratis dari [Google AI Studio](https://aistudio.google.com/).
2. Buat sebuah file baru bernama **`.env`** di *root directory* project (sejajar dengan file `pubspec.yaml`).
3. Buka file `.env` tersebut dan tambahkan baris berikut, ganti dengan API Key milik Anda:
   ```env
   GEMINI_API_KEY=isi_dengan_api_key_gemini_anda_di_sini
   ```
*(Catatan: File `.env` sudah dimasukkan ke dalam `.gitignore` sehingga aman dan tidak akan ikut ter-upload ke GitHub).*

### 4. Jalankan Aplikasi
Setelah semuanya siap, hubungkan perangkat Anda dan jalankan:
```bash
flutter run
```

---

## 📁 Struktur Direktori Utama

```text
lib/
├── controllers/       # Menangani logika bisnis (AuthController, dll)
├── screens/           # Halaman presentasi UI (View)
│   ├── auth/          # Login & Registrasi
│   ├── chat/          # Layar interaksi AI Gemini
│   ├── dashboard/     # Beranda dan ringkasan saldo
│   ├── profile/       # Pengaturan user, Biometrik, dan Feedback
│   └── statistic/     # Grafik dan riwayat transaksi
├── services/          # Layanan background (DatabaseHelper, NotificationHelper)
└── main.dart          # Entry point & inisialisasi aplikasi
```
