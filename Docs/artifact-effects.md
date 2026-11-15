# Artefak dan katalog

Daftar aktif hanya 15 artefak pada tabel referensi. Lima entri tambahan dihapus dari data master dan kartu buku. Scene artefak buatan pengguna tetap dipakai untuk pickup.

Efek pasif mengikuti koleksi permanen yang sudah digunakan game; Daun Kelor aktif setiap pickup. Mustika menahan satu serangan fatal, tersimpan di checkpoint, dan diisi ulang oleh `restore_life()` ketika kembali ke lobi. Bonus Pring berlaku pada hadiah resource kematian musuh, bukan peti.

Angka awal efek tercantum pada bagian EFEK di katalog dan Data/bestiary_data.json. Damage berupa integer dan bonus damage dibulatkan ke atas. Bleed tidak menumpuk; hit baru menyegarkan durasi. Gelombang Pecut mengenai semua musuh di depan, tanpa hit ganda pada target yang juga terkena pedang.

## Mengganti gambar

- Buku utama: buka Scenes/Interactables/bestiary_artifacts_tab.tscn. Ganti `Locked Portrait` pada root untuk gambar terkunci. Placeholder sekarang Assets/UI/artifact_locked.svg.
- Gambar terbuka: ganti texture pada `Book/EntryGrid/Entry_<id>/Portrait` setiap kartu. Ilustrasi sementara memakai texture kartu yang sudah ada.
- Katalog alternatif: ganti `image_path` dan `locked_image_path` pada entri Data/bestiary_data.json.
- Nama, gambar, kategori, dan deskripsi terkunci sampai artefak didapat. F6 juga mengikuti status penemuan; aktifkan `Preview All When Run Alone` secara eksplisit untuk preview seluruh isi.

## Integrasi musuh berikutnya

Dua implementasi musuh saat ini (Aul/Kuntilanak) sudah mendukung bleed, stun, reflect, dan resource. Musuh baru harus masuk grup `artifact_enemies`, menjalankan `artifact_status.tick`, dan memanggil `player.take_damage(amount, self, is_projectile)` untuk identitas penyerang/armor proyektil. Pemanggil debuff menggunakan `player.apply_negative_effect(kind, duration)`; poison/burn/bleed tersedia dan Daun Kelor menghapus seluruh status.

## Validasi

Tests/test_artifact_effects.gd memeriksa stats, crit, reach, regen, cleanse, shield/checkpoint, reflect, shockwave, bleed, stun, resource, dan double jump. Tests/test_bestiary_catalog.gd memeriksa identitas/gambar/deskripsi terkunci, filter, halaman, dan preview eksplisit.
