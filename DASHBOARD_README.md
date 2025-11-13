# Dashboard dan Kuesioner Tracer Study ITK

## Ringkasan Perubahan

### 1. Dashboard Baru (dashboard_page.dart)
Dashboard baru telah dibuat dengan fitur-fitur berikut:

#### KPI Cards (Key Performance Indicators)
- **Total Responden**: Jumlah total responden yang telah mengisi kuesioner
- **% Bekerja**: Persentase alumni yang bekerja (dari field f8)
- **Rata-rata Waktu Tunggu**: Rata-rata bulan menunggu pekerjaan pertama (dari field f502)
- **% Relevansi Pendidikan**: Persentase relevansi pendidikan dengan pekerjaan (dari field f14)
- **Rata-rata Pendapatan**: Rata-rata take home pay per bulan (dari field f505)
- **% Response Rate**: Tingkat respons kuesioner

#### Statistik Detail (8 Kategori)

**1. Status dan Kondisi Kerja Alumni**
- Status Alumni (f8) → Pie Chart
- Pekerjaan ≤6 Bulan/Sebelum Lulus (f504) → Donut Chart
- Waktu Tunggu Kerja (f502) → Bar Chart
- Distribusi Pendapatan (f505) → Histogram
- Lokasi Kerja (f5a1, f5a2) → Heat Map

**2. Profil Pekerjaan**
- Jenis Institusi (f1101) → Donut Chart
- Nama Perusahaan (f5b) → Table/List
- Posisi Wiraswasta (f5c) → Word Cloud
- Tingkat Tempat Kerja (f5d) → Stacked Bar Chart

**3. Relevansi Pendidikan**
- Relevansi Bidang Studi (f14) → Stacked Bar Chart
- Kesesuaian Tingkat Pendidikan (f15) → Pie Chart

**4. Kompetensi Alumni**
- Gap Analysis Kompetensi (f1761-f1774) → Radar Chart
  - Etika (saat lulus vs kebutuhan)
  - Keahlian bidang ilmu
  - Bahasa Inggris
  - Penggunaan TI
  - Komunikasi
  - Kerja sama tim
  - Pengembangan diri

**5. Metode Pembelajaran**
- Efektivitas Metode Pembelajaran (f21-f27) → Horizontal Bar Chart
  - Perkuliahan, Demonstrasi, Partisipasi proyek riset
  - Magang, Praktikum, Kerja lapangan, Diskusi

**6. Proses Pencarian Kerja**
- Timeline Pencari Kerja (f301-f303) → Bar Chart
- Strategi Pencarian Kerja (f401-f415) → Horizontal Bar Chart
- Efektivitas Lamaran (f6, f7, f7a) → Funnel Chart
- Status Aktif Pencarian Kerja (f1001) → Pie Chart

**7. Pembiayaan Pendidikan**
- Sumber Dana Kuliah (f1201) → Pie Chart
- Sumber Biaya Studi Lanjut (f18a) → Pie Chart
- Detail Studi Lanjut (f18b-f18d) → Table

**8. Analisis Ketidaksesuaian Pekerjaan**
- Alasan Mengambil Pekerjaan Tidak Sesuai (f1601-f1613) → Horizontal Bar Chart

### 2. Kuesioner Lengkap dalam Bahasa Indonesia

Kuesioner telah diperbarui dengan **90+ pertanyaan** yang mencakup:

#### Status dan Kondisi Kerja Alumni
- f8: Status Alumni (Bekerja, Wiraswasta, Studi lanjut, dll)
- f504: Pekerjaan sebelum/sesudah 6 bulan lulus
- f502: Waktu tunggu mendapat pekerjaan (dalam bulan)
- f505: Rata-rata pendapatan per bulan
- f5a1: Provinsi tempat kerja
- f5a2: Kota/Kabupaten tempat kerja

#### Profil Pekerjaan
- f1101: Jenis institusi (Pemerintah, BUMN, Swasta, dll)
- f5b: Nama perusahaan
- f5c: Jabatan (khusus wiraswasta)
- f5d: Tingkat tempat kerja (Lokal, Nasional, Multinasional)

#### Relevansi Pendidikan
- f14: Keeratan hubungan bidang studi dengan pekerjaan
- f15: Kesesuaian tingkat pendidikan

#### Kompetensi Alumni (Gap Analysis)
Setiap kompetensi memiliki 2 pertanyaan:
- Tingkat kompetensi saat lulus
- Tingkat kompetensi yang dibutuhkan di pekerjaan

Kompetensi yang dinilai:
- f1761-f1762: Etika
- f1763-f1764: Keahlian bidang ilmu
- f1765-f1766: Bahasa Inggris
- f1767-f1768: Penggunaan TI
- f1769-f1770: Komunikasi
- f1771-f1772: Kerja sama tim
- f1773-f1774: Pengembangan diri

#### Metode Pembelajaran
Rating 1-5 untuk setiap metode:
- f21: Perkuliahan
- f22: Demonstrasi
- f23: Partisipasi proyek riset
- f24: Magang
- f25: Praktikum
- f26: Kerja lapangan
- f27: Diskusi

#### Proses Pencarian Kerja
Timeline:
- f301: Bulan mulai mencari kerja sebelum lulus
- f302: Bulan mulai mencari kerja setelah lulus
- f303: Aktif mencari dalam 4 minggu terakhir

Strategi (Multiple response):
- f401-f415: 15 strategi pencarian kerja

Efektivitas:
- f6: Jumlah perusahaan dilamar
- f7: Jumlah perusahaan merespons
- f7a: Jumlah undangan wawancara

Status:
- f1001-f1002: Status aktif pencarian kerja

#### Pembiayaan Pendidikan
- f1201-f1202: Sumber biaya kuliah S1
- f18a: Sumber biaya studi lanjut
- f18b-f18d: Detail studi lanjut (PT, Prodi, Tanggal)

#### Analisis Ketidaksesuaian Pekerjaan
- f1601-f1613: 13 alasan mengambil pekerjaan tidak sesuai

### 3. Integrasi Dashboard ke Home Page

Dashboard ditampilkan di home page untuk:
- **Admin**: Melihat dashboard lengkap
- **Team Tracer (Surveyor)**: Melihat dashboard lengkap
- **Team Prodi**: Melihat dashboard lengkap
- **Alumni (User)**: Tetap melihat daftar kuesioner untuk diisi

Dashboard diposisikan:
- **Di atas menu drawer**
- **Di bawah username/profile**
- **Dapat di-scroll** untuk melihat semua statistik

### 4. Perubahan Database

Menambahkan method baru di `database_helper.dart`:
```dart
Future<List<Map<String, dynamic>>> getAllResponses()
```

Method ini mengambil semua respons dari database untuk kalkulasi statistik dashboard.

### 5. Dependencies Baru

Ditambahkan ke `pubspec.yaml`:
```yaml
fl_chart: ^0.66.0  # Untuk visualisasi chart di dashboard
```

## Cara Menggunakan

### Untuk Admin/Team Tracer/Team Prodi:
1. Login dengan akun admin/surveyor/team_prodi
2. Dashboard akan muncul di home page
3. Scroll untuk melihat semua KPI dan statistik
4. Pull down untuk refresh data

### Untuk Alumni (User):
1. Login dengan akun user
2. Pilih kuesioner "Tracer Study Alumni ITK 2024"
3. Isi semua pertanyaan (90+ pertanyaan)
4. Submit kuesioner
5. Data akan otomatis masuk ke dashboard

## Field Mapping

Setiap pertanyaan memiliki field ID yang sesuai dengan requirement dashboard:
- **f8**: Status Alumni
- **f502**: Waktu tunggu kerja
- **f504**: Pekerjaan sebelum 6 bulan
- **f505**: Pendapatan
- **f5a1-f5a2**: Lokasi kerja
- **f1101**: Jenis institusi
- **f5b-f5d**: Detail pekerjaan
- **f14-f15**: Relevansi pendidikan
- **f1761-f1774**: Kompetensi (14 pertanyaan)
- **f21-f27**: Metode pembelajaran (7 pertanyaan)
- **f301-f303**: Timeline pencarian kerja
- **f401-f415**: Strategi pencarian kerja (15 pertanyaan)
- **f6-f7a**: Efektivitas lamaran
- **f1001-f1002**: Status aktif pencarian
- **f1201-f1202**: Pembiayaan pendidikan
- **f18a-f18d**: Detail studi lanjut
- **f1601-f1613**: Alasan ketidaksesuaian pekerjaan (13 pertanyaan)

## Catatan Implementasi

### Chart Placeholders
Saat ini dashboard menampilkan **placeholder** untuk chart. Implementasi chart visual lengkap dengan fl_chart akan memerlukan:
1. Parsing data dari responses
2. Agregasi data berdasarkan field
3. Render chart dengan fl_chart widgets

### Future Enhancements
1. **Visualisasi Chart**: Implementasi chart interaktif dengan fl_chart
2. **Filter Data**: Filter berdasarkan tahun lulus, program studi, dll
3. **Export Data**: Export statistik ke PDF/Excel
4. **Real-time Updates**: WebSocket untuk update real-time
5. **Heat Map**: Implementasi heat map Indonesia untuk lokasi kerja

## Struktur File

```
lib/
├── pages/
│   ├── dashboard_page.dart          # Dashboard baru
│   ├── home_page.dart               # Diupdate dengan dashboard
│   ├── take_questionnaire_page.dart # Halaman pengisian kuesioner
│   └── ...
├── services/
│   ├── survey_storage.dart          # Kuesioner lengkap 90+ pertanyaan
│   └── ...
└── database/
    └── database_helper.dart         # Method getAllResponses() baru
```

## Testing

Untuk testing dashboard:
1. Pastikan ada data respons di database
2. Login sebagai admin/surveyor/team_prodi
3. Buka home page
4. Dashboard akan menampilkan KPI dan statistik
5. Pull to refresh untuk update data

## Support

Jika ada pertanyaan atau issues, silakan hubungi tim development.
