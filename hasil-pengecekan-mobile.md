# Pemeriksaan mobile setelah revisi

Proyek: `D:\apps\laragon\www\Koperasi Flutter`.

## Hasil

- `flutter analyze`: No issues found (sebelum penambahan tes audit).
- `flutter test --concurrency=1`: 39 tes bawaan lulus.
- `flutter test --concurrency=1 audit/pos_audit_test.dart`: 5 tes audit gagal, seluruhnya membuktikan masalah fungsional di bawah.
- Tes audit memakai HTTP mock; tidak membuat transaksi atau mengubah data toko. Kode aplikasi tidak diubah pada pemeriksaan ini.

## Temuan

### P1 — URL seluruh layanan POS kehilangan alamat server

`lib/services/pos_service.dart:33`, `:60`, `:92`, `:137`, `:183`, `:299`, dan `:327` menggunakan URI relatif seperti `/products`, `/sales`, `/calculate`, `/checkout`. Properti `baseUrl` tersedia, tetapi tidak dipakai. Wrapper `api_http.dart` meneruskan URL langsung ke HTTP client tanpa menambahkan server. Pada Android/desktop, request tidak memiliki host tujuan. Katalog dan riwayat dapat terlihat kosong karena exception ditelan dan dikembalikan sebagai list kosong; pembayaran gagal.

Tes membuktikan URL produk dan checkout yang dikirim tidak sesuai `${ApiConfig.posUrl}/...`.

### P1 — QRIS kehilangan order ID pada URL

`lib/services/pos_service.dart:232`, `:253`, dan `:270` membentuk `/qris/check-status/`, `/qris/cancel/`, `/qris/simulate/` tanpa memasukkan parameter `orderId`. Jadi, menambahkan host saja belum cukup: rute tetap tidak menunjuk transaksi yang diperiksa/dibatalkan.

Tes polling dan cancel dengan `ORDER-AUDIT` membuktikan ID tersebut tidak ikut terkirim.

### P1 — Struk tunai memakai perkiraan lokal, bukan hasil server

`lib/pages/pos/widgets/cash_payment_bottom_sheet.dart:91` menghitung kembalian dari `widget.finalAmount`; sekitar baris 108, payload struk memakai nilai itu lagi dan mengabaikan `result['total']`/`result['change']`.

Tes widget: tampilan awal Rp10.000, server mengembalikan total Rp9.000, uang diterima Rp10.000, kembalian Rp1.000. Struk yang dikirim ke tampilan tetap mencatat total Rp10.000. Assertion gagal sebelum pemeriksaan kembalian, sedangkan pembacaan kode menunjukkan kembalian juga memakai perkiraan awal.

### P2 — Pratinjau pembayaran belum memakai kalkulasi server

`lib/pages/pos/pos_page.dart:122` dan `lib/pages/pos/widgets/pos_cart_bottom_sheet.dart:94` menghitung harga member dan potongan poin secara lokal. Tidak ditemukan pemanggilan `calculateOrder()` dari halaman mobile. Kalkulasi server juga memperhitungkan diskon global/promo/pajak dan ketersediaan poin saat transaksi. Akibatnya angka uang pas/total yang ditampilkan dapat berbeda dari nilai yang diterima server. Temuan ini berdasarkan penelusuran kode, bukan transaksi gateway nyata.

## Bagian lain yang diperiksa

- Form produk baru menyediakan validasi supplier wajib.
- Barang masuk mengirim supplier dan tanggal kedaluwarsa; riwayat mutasi mengikuti cursor pagination, dengan tes kegagalan pemuatan.
- Halaman retur pembelian mengirim dokumen penerimaan, supplier, dan batch melalui endpoint retur baru; tes widget dan service terkait lulus.
- Dialog retur penjualan memakai `refund_budget` dari server untuk pratinjau refund.
- Request mutasi memakai bearer token dan idempotency key; tes retry/double-tap yang ada lulus.

Ini bukan pernyataan bahwa seluruh alur end-to-end sudah berjalan: masalah POS di atas menghalangi alur kasir utama.

## Perangkat

Flutter mendeteksi Infinix X6833B, Android 14. Aplikasi `com.example.flutter_kop` terpasang dengan versi 1.0.0 (versionCode 1), `lastUpdateTime=2026-10-13 22:50:24` menurut Android. Saat diperiksa, `pidof` tidak menunjukkan proses aplikasi berjalan. Pemeriksaan perangkat hanya baca-saja; tidak dilakukan instalasi, login, atau transaksi. APK yang terpasang belum dapat memvalidasi revisi kode yang dikerjakan setelah tanggal tersebut.

Prioritas: perbaiki URL POS dan order ID QRIS; samakan pratinjau/struk dengan kalkulasi server; jalankan ulang lima tes audit; kemudian build dan uji APK terbaru pada HP.
