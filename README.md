# Capsicum App 
**Aplikasi Deteksi Penyakit Daun Cabai (Tugas Akhir Project)**

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) 
![TensorFlow Lite](https://img.shields.io/badge/TensorFlow_Lite-%23FF6F00.svg?style=for-the-badge&logo=TensorFlow&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

Capsicum App adalah aplikasi *mobile* berbasis **Flutter** yang dirancang khusus untuk mendeteksi dan mengklasifikasikan penyakit pada tanaman cabai secara *real-time*. Aplikasi ini berjalan menggunakan arsitektur **Local-First**, memanfaatkan **YOLOv11-Segmentation** dan **TensorFlow Lite (TFLite)** yang tertanam langsung di dalam perangkat (on-device inference), sehingga pendeteksian dapat dilakukan **tanpa memerlukan koneksi internet**.

---

## Fitur Utama (Key Features)

1. **Deteksi Kamera Real-time (On-Device Inference)** 
   Arahkan kamera ke daun cabai, dan AI (TFLite) akan langsung memberikan hasil segmentasi penyakit yang ditemukan beserta tingkat keparahannya secara instan.
2. **Offline Pertama (Local-First)** 
   Tidak ada data gambar yang dikirim ke server luar. Inference AI bekerja murni 100% secara offline di perangkat pengguna.
3. **Pusat Informasi Penyakit (Information Hub)**
   Menyediakan galeri interaktif (karosel gambar) dan informasi detail seputar patogen cabai, meliputi:
   - Daun Sehat (Healthy Leaf)
   - Bercak Daun Serkospora (Cercospora Leaf Spot)
   - Bercak Bakteri (Bacterial Spot)
   - Virus Keriting (Curl Virus)
   - Bercak Putih (White Spot)
4. **Rekomendasi Penanganan & Referensi Video Terintegrasi**
   Setiap penyakit dilengkapi dengan modul penanganan, termasuk saran penggunaan bahan aktif dan pestisida, serta referensi sumber resmi dan video edukasi langsung (YouTube/TikTok).
5. **Riwayat Pemindaian (Detection History)**
   Semua data hasil deteksi (gambar, lokasi GPS, dan detail penyakit) disimpan ke penyimpanan lokal menggunakan **Hive Database** agar bisa diulas kembali.

---

## Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Kecerdasan Buatan (AI):** YOLOv11-Segmentation diekspor ke [TensorFlow Lite](https://www.tensorflow.org/lite)
* **State Management:** [Riverpod](https://riverpod.dev/)
* **Local Database:** [Hive](https://pub.dev/packages/hive)
* **Akses Perangkat:** Geolocator (GPS), Camera (Visi Mesin)

---

## Cara Instalasi & Menjalankan (Getting Started)

Pastikan lingkungan Anda telah terpasang **Flutter SDK** (versi stabil terbaru).

**1. Clone Repositori Ini**
```bash
git clone https://github.com/Ilhammm01/capsicum.git
cd capsicum
```

**2. Unduh Semua Dependensi**
```bash
flutter pub get
```

**3. Pastikan Model TFLite Tersedia**
Pastikan file model `best.tflite` dan `labels.txt` sudah berada di dalam folder `assets/models/`.

**4. Jalankan Aplikasi**
*Hubungkan perangkat Android/iOS atau gunakan Emulator.*
```bash
flutter run
```

---

## Struktur Folder Utama (Project Structure)
Struktur diatur dengan pola *Feature-First Architecture* untuk kemudahan pemeliharaan:
```text
lib/
├── app/               # Pengaturan Tema (Theme), Rute (Router), dll.
├── core/              # Services (Kamera, Lokasi, Akses API)
├── features/          
│   ├── detection/     # UI & Logika untuk Pemindaian Kamera & TFLite
│   ├── history/       # UI & Logika untuk Riwayat Data & Information Hub
│   └── scan_detail/   # UI Detail Penyakit & Rekomendasi
├── shared_data/       # Widget & Komponen umum yang dipakai bersama
└── main.dart          # Entry point aplikasi
```

---

**Developed for Academic Purposes (Tugas Akhir Universitas Negeri Makassar) © 2026**
