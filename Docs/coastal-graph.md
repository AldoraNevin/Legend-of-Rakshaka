# Coastal: template, socket, dan layout 2D

Generator aktif memilih 8 template Resource dari
`Scenes/Rooms/Stage/Coastal/Templates/catalog.tres`. Graph hanya menyimpan urutan
entrance -> combat -> exit dan dua cabang treasure. `coastal_placer.gd` memasangkan
socket berlawanan, mencoba kiri/kanan/atas/bawah, dan melakukan backtracking jika
ruang atau koridor berbenturan. Seed yang sama menghasilkan susunan yang sama.
Pencarian dibatasi 4.000 percobaan per attempt, maksimal 8 attempt; kegagalan
memberi error dan tidak diam-diam mengganti level menjadi lorong lurus.

## Edit / tambah template lewat Godot

1. Buka `Scenes/Rooms/Stage/Coastal/coastal_template_preview.tscn` di editor 2D.
2. Pilih node `CoastalTemplatePreview`. Isi properti `Template` dengan salah satu
   `.tres` di folder `Templates`. Preview menampilkan bentuk biru, socket hijau,
   anchor putih, dan status validasi. Preview ini alat authoring, bukan level game.
3. Untuk variasi baru, duplikat salah satu `.tres` menjadi nama baru. Ubah
   `template_id` (unik), `display_name`, `size`, dan `air_regions` di Inspector.
   `air_regions` adalah gabungan persegi panjang ruang kosong; overlap antarbagiannya
   diperbolehkan. Dinding dibangun otomatis hanya pada batas luarnya.
4. Sesuaikan socket dan anchor jika ukuran berubah. Socket merupakan subresource
   di dalam file template, sehingga dapat diperiksa satu per satu di Inspector.
5. Tambahkan Resource baru ke array `Room Templates` pada `catalog.tres`.
6. Jalankan validasi dan tes fisika di bawah sebelum memakai template baru.

## Kontrak versi awal

Kontrak sengaja dibatasi agar template yang kamu tambahkan tetap bisa dilewati:

- `size`: kelipatan 32 px; minimum 384 x 192. Semua `air_regions` berada di dalam
  size, dimensinya positif dan koordinat/ukurannya kelipatan 16 px.
- Sisakan pita kosong penuh setinggi 128 px di bagian bawah ruangan.
- Sisakan kolom kosong tengah selebar 192 px dari atas sampai lantai.
  Bagian lain bebas dibentuk sebagai L/T, gua, aula atau menara.
- Anchor tetap `(64, tinggi - 34)` pada lantai kiri, aman dari bukaan vertikal.
- Socket kiri: `(0, tinggi - 64)`, kanan: `(lebar, tinggi - 64)`, bukaan 128 px.
- Socket atas: `(lebar / 2, 0)`, bawah: `(lebar / 2, tinggi)`, bukaan 192 px.
- Maksimal satu socket untuk setiap arah. Socket boleh dihapus untuk membatasi
  arah sambungan template. Socket yang tidak dipakai tetap tertutup dinding.
- `allowed_kinds` membatasi fungsi template: entrance, combat, exit, treasure.
- Jangan mengubah ukuran bukaan/posisi socket secara bebas tanpa memperbarui
  pembangun jalur dan tes fisika. Validator menolak perubahan yang tidak didukung.

Ini template geometri berbasis Resource, bukan scene dekorasi bebas. Aset scene
coastal lama dan `coastal_profiles.gd` disimpan sebagai referensi legacy dan tidak
lagi dipakai generator aktif. Dekorasi runtime berada di `coastal_backdrop.gd`,
selalu di belakang pemain dan dipotong mengikuti ruang kosong template.

## Koneksi dan akses

Koridor horizontal memiliki tinggi 128 px; panjang dipilih dari 128/192/256 px.
Koridor vertikal memakai pijakan one-way beda tinggi maksimal 40 px. Ada ruang di samping
pijakan untuk turun, serta platform penangkap di bagian bawah shaft. Tidak perlu
teleport, dash, atau upgrade kemampuan. Bukaan lantai dapat dilompati.

Room bounds dan koridor diberi jarak aman 16 px. Koridor hanya boleh menyentuh
ruangan pemilik kedua socket-nya, tidak memotong ruangan atau koridor lain.
Shell collision dibangun dari gabungan ruang kosong sehingga pintu tersambung
benar-benar terbuka. Kedua treasure opsional dan tidak mengunci exit.

## Peta M dan pengujian

Peta M membaca ruang kosong hasil akhir dan collision shape yang benar-benar
terpasang. Tidak ada garis graph yang dipakai sebagai koridor palsu. M/Esc menutup
peta; gameplay dijeda selama peta terbuka.

Tes: `test_coastal_layout.gd` (200 seed, semua arah, overlap, socket, geometri),
`test_coastal_physics.gd` (spawn sampai exit), `test_coastal_round_trip.gd`
(32 seed pergi-pulang jalur utama), `test_coastal_treasure_physics.gd`
(pergi-pulang cabang), `test_coastal_map.gd`, dan `test_room_exit.gd`.

Contoh perintah dari direktori proyek:

```text
Godot --headless --fixed-fps 60 --path . --log-file test.log --script Tests/test_coastal_layout.gd
```

Tes render `test_coastal_visibility.gd` dijalankan tanpa `--headless` dan memastikan
sprite pemain benar-benar terlihat. Untuk memperbarui screenshot map, jalankan
`test_coastal_map.gd` tanpa `--headless` lalu tambahkan `-- --capture`.

## Platform parkour dan tileset

Pijakan zigzag kini memakai pengaturan di `Assets/Tileset/coastal_style.tres`:
lebar 96 px, offset 32 px, dan jarak maksimal 40 px yang dibagi merata.
Pijakan masuk 144 px dan penangkap 192 px tetap dipertahankan.
Semua room mendapat balkon samping jika air_regions cukup luas, dengan
pijakan awal yang tidak menghalangi spawn/reward/pintu. Setiap template memiliki
Automatic Balconies dan Extra Platforms untuk pengeditan lewat Inspector.

Visual memakai TileSet atlas 16 px dengan PNG yang dapat diedit. Collision
terpisah dari gambar; map M tetap mengikuti shell dan platform sebenarnya.
Baca [panduan tileset dan platform](coastal-tileset-editing.md) untuk langkah
pengeditan dan contoh room latihan. Tes `test_coastal_balconies.gd` memeriksa
akses platform samping dengan collision nyata.
