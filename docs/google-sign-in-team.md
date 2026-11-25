# Google Sign-In setelah clone/pull di komputer lain

Kode yang sama dapat menghasilkan APK dengan sertifikat berbeda. Android
mengenali aplikasi OAuth melalui **package name dan SHA-1 kunci penandatangan APK**.
`git pull` tidak menyalin debug keystore komputer pembuat awal.
SHA yang diperlukan adalah milik komputer pembuat APK, bukan milik ponsel.

## Langkah untuk setiap anggota tim yang membangun aplikasi

1. Jalankan dari root proyek:

   ```powershell
   flutter pub get
   cd android
   .\gradlew.bat :app:checkGoogleSignInDebug --console=plain
   cd ..
   ```

   Pada macOS/Linux gunakan `./gradlew`. Perintah mencetak package name,
   **SHA-1**, dan **SHA-256** ke terminal. Jika konfigurasi belum cocok, build
   berhenti dengan petunjuk. Pemeriksaan yang sama berjalan pada `flutter run`
   dan build APK. Untuk release, jalankan `:app:checkGoogleSignInRelease`.
   Alternatif bawaan Android untuk melihat semua sertifikat: `:app:signingReport`.

2. Kirim **nilai SHA-1 dan SHA-256 tersebut** kepada pemilik proyek Firebase.
   Jangan mengirim `debug.keystore`, password, atau private key.
3. Pemilik proyek membuka Firebase Console → proyek **nalara-e1c49** →
   **Project settings → General → Your apps → com.example.nalara → Add fingerprint**.
   Tambahkan SHA-1 dan SHA-256 setiap pembuat APK. **Pertahankan fingerprint
   anggota tim lainnya.** Jika Firebase menyatakan fingerprint sudah terdaftar,
   lanjutkan pengunduhan konfigurasi.
4. Pada Authentication → Sign-in method pastikan provider **Google** aktif.
   Unduh ulang **google-services.json** dari pengaturan aplikasi Android dan
   gantikan `android/app/google-services.json`.
5. Commit konfigurasi terbaru agar anggota tim bisa melakukan `git pull`.
   Jangan mengedit `certificate_hash` atau OAuth client ID secara manual:
   perubahan lokal saja tidak mendaftarkan sertifikat pada server Google.
6. Hentikan aplikasi, lalu jalankan `flutter run` lagi. Konfigurasi native ini
   memerlukan rebuild; hot reload tidak cukup.

Firebase Console tidak dapat diperbarui dari kode Flutter. Fingerprint anggota
tim lain harus didaftarkan oleh orang yang memiliki akses ke proyek.

## Jika hanya ingin mencoba aplikasi

Bagikan **APK yang sama** hasil build komputer yang sertifikatnya sudah
terdaftar. Pengguna yang memasang APK tersebut tidak perlu mendaftarkan ponselnya.
Ini berbeda dengan membangun APK sendiri dari GitHub.

## Batas pemeriksaan otomatis

Task memeriksa sertifikat terhadap snapshot konfigurasi lokal, bukan membaca
status OAuth di server. Setelah menambah fingerprint di Firebase, selalu unduh
konfigurasi baru. Pemeriksaan ini mengikuti konfigurasi saat ini: tanpa product
flavor dan satu file `android/app/google-services.json`. Jika kelak menambahkan
flavor/config per varian, sesuaikan pemeriksaan dengan file varian tersebut.

Jika APK yang sama masih gagal pada ponsel lain, catat kode/pesan error persisnya
dan tahap gagalnya. Periksa Google Play services dan koneksi perangkat, serta
aturan Firestore jika pesan mengatakan akun sudah masuk tetapi profil gagal
tersimpan. Jangan menyimpulkan bahwa semua kegagalan adalah masalah SHA.

Referensi: [konfigurasi resmi Google Sign-In Android](https://pub.dev/packages/google_sign_in_android)
dan [pengaturan Google Sign-In Firebase Android](https://firebase.google.com/docs/auth/android/google-signin).
