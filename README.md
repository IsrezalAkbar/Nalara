# Nalara

## Shift kasir

Buka **Profil → Shift Kasir** untuk memulai shift dengan nama petugas dan modal
awal. Satu akun toko hanya memiliki satu shift aktif. Penjualan selama periode
shift dihitung otomatis dari transaksi tersimpan, termasuk shift lintas hari.
Kas seharusnya adalah modal awal ditambah penjualan tunai setelah kembalian;
QRIS hanya masuk total penjualan. Saat menutup shift, masukkan uang tunai aktual
dan catatan opsional untuk menyimpan selisih kas di riwayat. Kas masuk/keluar di
luar penjualan belum dicatat oleh fitur ini.

Tab **Shift Aktif** berisi mulai shift dan pemantauan kas. Tab **Riwayat Shift**
menampilkan hari ini secara default; gunakan **Pilih Tanggal**, panah hari,
atau **Hari Ini** untuk berpindah tanggal. Ringkasan shift dikelompokkan menurut
tanggal selesai dan tetap mencakup seluruh periode shift. **Log Aktivitas**
mencatat waktu mulai dan tutup pada tanggal masing-masing, termasuk shift
lintas tengah malam. Setelah tutup shift, aplikasi membuka riwayat hari ini.
Input modal awal dan uang tunai aktual memakai pemisah ribuan titik otomatis
(misalnya `100.000`); nilai tetap disimpan sebagai angka rupiah utuh.

Data disimpan pada `users/{uid}/shifts` dan `users/{uid}/shiftState/current`.
Waktu mulai/selesai berasal dari server. Mulai dan tutup shift memerlukan
koneksi; aturan mencegah shift tumpang tindih dan perubahan shift yang selesai.
Transaksi di luar periode shift tetap berada dalam riwayat transaksi biasa.

Sebelum memakai fitur shift pada Firebase live, publikasikan aturan terbaru:

```powershell
firebase deploy --only firestore:rules --project nalara-e1c49
```

## Pembayaran dan laporan transaksi

Kasir mendukung **Tunai** dan **QRIS manual**. Untuk QRIS, pelanggan membayar
melalui QRIS toko di luar aplikasi. Kasir memeriksa pembayaran lalu mencentang
**Saya sudah menerima pembayaran QRIS** dan memilih **Catat QRIS**. Nalara hanya
mencatat transaksi; tidak membuat kode QR atau memeriksa pembayaran melalui
penyedia eksternal. Stok berkurang setelah transaksi berhasil disimpan.

Menu **Transaksi → Laporan Transaksi** menampilkan penjualan hari ini berdasarkan
tanggal lokal perangkat: total nominal dan jumlah transaksi, nominal/jumlah
transaksi Tunai dan QRIS, serta produk dan kuantitas yang terjual. Laporan ini
tersedia untuk Basic dan Premium dan tidak mengikuti filter tab Riwayat.
Metode pembayaran dapat diaktifkan/nonaktifkan melalui pengaturan profil.

Sebelum menggunakan QRIS pada Firebase live, publikasikan aturan terbaru karena
aturan lama hanya menerima pembayaran Tunai:

```powershell
firebase deploy --only firestore:rules --project nalara-e1c49
```

Transaksi QRIS disimpan dengan `method: 'QRIS'` dan `cash: 0`; nilai pembayaran
tetap ada pada `total`. Transfer Bank tidak tersedia sebagai metode pembayaran.

Jika Google Sign-In gagal setelah anggota tim melakukan clone/pull dan membangun
APK sendiri, ikuti [panduan fingerprint setiap komputer](docs/google-sign-in-team.md).
Build Android sekarang memeriksa kunci penandatangan terhadap konfigurasi lokal
dan mencetak SHA-1/SHA-256 yang perlu didaftarkan.

## Menjalankan login Google (Android)

Proyek Firebase: `nalara-e1c49`. Package Android: `com.example.nalara`.
Tombol **Daftar dengan Google** dan **Masuk dengan Google** menggunakan alur
yang sama: Firebase Authentication membuat akun pada login pertama dan memakai
akun yang sama untuk login berikutnya. Setelah autentikasi, aplikasi menyimpan
`email` dan nama awal di Cloud Firestore pada `users/{uid}`. Data toko dan nama
profil yang sudah diedit dipertahankan.

### Konfigurasi Firebase yang diperlukan

1. Pada Firebase Console → Authentication → Sign-in method, aktifkan **Google**
   dan pilih email dukungan proyek. Aktifkan **Email/Password** untuk login biasa.
2. Pada Project settings → Your apps → Android `com.example.nalara`, tambahkan
   fingerprint kunci yang dipakai untuk membangun APK. Kunci debug komputer ini
   diperiksa pada 20 Oktober 2026:

   ```text
   SHA-1:
   F4:C3:4E:B6:DE:53:52:67:F1:18:DC:AD:0E:FC:7D:0D:3A:8C:33:F9

   SHA-256:
   CA:5D:BF:C1:BE:7F:C8:0B:8A:D8:F1:19:D5:F2:B1:B4:08:F9:42:E1:92:D6:71:1D:FD:EE:E8:46:7F:BB:38:1D
   ```

   `android/app/google-services.json` saat pemeriksaan 26 Oktober 2026 memuat SHA-1
   `F4:C3:4E:B6:DE:53:52:67:F1:18:DC:AD:0E:FC:7D:0D:3A:8C:33:F9`.
   Komputer lain yang membangun APK biasanya menggunakan kunci debug berbeda.
   Tambahkan fingerprint yang diperlukan tanpa menghapus milik komputer lain.
   Jangan mengedit fingerprint di JSON secara manual; pendaftaran harus
   dilakukan di Firebase/Google Cloud.
3. Unduh ulang `google-services.json` dan gantikan file di `android/app/`.
   Pastikan ada OAuth client bertipe `3` (web client untuk token Firebase).
4. Buat database Cloud Firestore `(default)` bila belum tersedia, lalu
   publikasikan [firestore.rules](firestore.rules) melalui tab Rules. Rules ini
   mengizinkan email yang cocok dengan akun Firebase Auth dan membatasi akses
   profil ke pemiliknya.
5. Bangun ulang dan jalankan aplikasi; perubahan konfigurasi Android memerlukan
   rebuild, bukan hanya hot reload:

   ```powershell
   flutter run
   ```

Dengan Firebase CLI yang sudah login, fingerprint dan rules juga dapat
diperbarui menggunakan:

```powershell
firebase login --reauth
firebase apps:android:sha:create 1:149746913554:android:7564226ad65b9706c163cb F4C34EB6DE535267F118DCAD0EFC7D0D3A8C33F9 --project nalara-e1c49
firebase apps:android:sha:create 1:149746913554:android:7564226ad65b9706c163cb CA5DBFC1BE7FC80B8AD8F119D5F2B1B408F942E192D6711DFDEEE8467FBB381D --project nalara-e1c49
firebase apps:sdkconfig ANDROID 1:149746913554:android:7564226ad65b9706c163cb --project nalara-e1c49 --out android/app/google-services.json
firebase deploy --only firestore:rules --project nalara-e1c49
```

Perubahan Firebase live belum diterapkan oleh perbaikan ini: sesi CLI tersimpan
ditolak dengan HTTP 401 dan refresh token gagal. Aktivasi provider dan
fingerprint yang terdaftar di server belum dapat diverifikasi.

### Verifikasi

- Pilih akun Google di halaman masuk maupun daftar. Periksa akun pada
  Authentication → Users serta `email`/`name` pada Firestore → `users/{uid}`.
- Keluar dan masuk kembali; data toko dan nama profil harus tetap sama.
- Batalkan pemilih akun; aplikasi menampilkan pesan dan tombol dapat dicoba lagi.
- Jika autentikasi berhasil tetapi penyimpanan profil gagal, aplikasi menampilkan
  pesan dengan tombol **Coba lagi**, bukan langsung masuk ke halaman toko.
- Pastikan perangkat bisa mengakses internet. Log perangkat saat pemeriksaan
  juga menunjukkan kegagalan DNS untuk `firestore.googleapis.com`.

Pengujian lokal:

```powershell
flutter analyze --no-pub
flutter test --no-pub
firebase emulators:exec --project demo-nalara --only firestore,storage "node --test firebase-tests/rules.test.mjs"
```

Referensi: [konfigurasi dan diagnosis Google Sign-In Android](https://pub.dev/packages/google_sign_in_android)
dan [Google Sign-In dengan Firebase Authentication](https://firebase.google.com/docs/auth/flutter/federated-auth).
