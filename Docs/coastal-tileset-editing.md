# Mengedit visual dan platform coastal

## Aset stage 1 yang aktif

Terrain dan platform coastal sekarang memakai `Assets/Tileset/Environment/tileset pantai.png`.
Dekorasi memakai `Assets/Tileset/Environment/tileset pantai(1).png` (pilar, panji,
guci, batu, kerang, lentera). Rectangle atlas terpusat di
`Script/Stage/coastal_asset_art.gd`; gambar sumber tidak diubah. Aset diperkecil
ke grid gameplay 16 px, platform setinggi 8 px. Dekorasi bersifat visual saja.
Background gameplay sekarang memakai empat layer pantai melalui
`Script/Stage/coastal_parallax.gd`. Urutan gambar: langit (1), laut (3), istana (2),
reruntuhan (4), dengan faktor gerak 0.025 / 0.10 / 0.16 / 0.30.
Gambar berulang horizontal; gerak vertikal dibatasi agar tidak membuka area kosong.
Dinding samping dan plafon tidak digambar, tetapi collision shell tetap aktif
sebagai batas player. Permukaan lantai tetap terlihat.
Preview TileSet lama hanya mengedit atlas cadangan, bukan terrain baru. Preview template menampilkan
pijakan baru. Jalankan `Scenes/Rooms/Stage/coastal_room.tscn` untuk melihat komposisi.
Collision, rute, dan penempatan treasure tetap berasal dari generator.

## 1. Mengganti gambar tile

Atlas aktif: `Assets/Tileset/Sprites/coastal_ruins.png`, ukuran 128 x 64 px.
Grid: 16 x 16 px, 8 kolom dan 4 baris. Semua gambar asli proyek, bukan aset
Dead Cells. File SVG di folder yang sama merupakan sumber gambar awal;
runtime memakai PNG, jadi mengedit SVG saja tidak mengubah level.

| Baris (mulai 0) | Isi | Dipakai untuk |
| --- | --- | --- |
| 0 | Batu terang berlumut | Permukaan lantai dan platform |
| 1 | Batu retak | Dinding dan bagian bawah lantai |
| 2 | Bata gelap | Background ruangan/koridor |
| 3, kolom 0–3 | Panji | Dekorasi |
| 3, kolom 4–5 | Pilar | Dekorasi |
| 3, kolom 6 | Lampu | Dekorasi |
| 3, kolom 7 | Tanaman | Tile cadangan untuk dekorasi manual |

1. Buka PNG di editor gambar seperti Aseprite atau Krita. Aktifkan grid 16 px.
2. Gambar ulang tiap sel; pertahankan ukuran atlas dan posisi sel.
3. Pertahankan tepi atas baris 0 yang terang. Platform one-way menggunakan
   8 piksel teratas sel ini, sehingga bagian atas menunjukkan posisi collision.
4. Simpan PNG. Godot mengimpor ulang, lalu jalankan ulang room.

Godot mengatur atlas dan penempatan tile; menggambar piksel dilakukan di editor
gambar. Collision tidak disimpan di TileSet ini: generator tetap membangun
collision dari air_regions, socket, dan daftar platform. Mengubah gambar tidak
mengubah jalur fisik atau map M.

## 2. Memeriksa TileSet di Godot

1. Buka `Scenes/Rooms/Stage/Coastal/coastal_tileset_preview.tscn`.
2. Pilih node `PaintHere` lalu klik properti Tile Set / panel TileSet bawah.
3. Atlas source ID 0 memakai `coastal_tileset.tres`, Texture Region Size 16 x 16.
4. Kamu bisa mengecat tile percobaan pada node PaintHere di bawah gambar atlas.
   Scene ini tempat latihan; lukisan di sini tidak mengubah level PCG.
5. Kalau mengganti PNG lewat properti Texture atlas, pertahankan susunan sel,
   source ID 0, tanpa margin/separation. Jika susunannya berbeda, sesuaikan
   pemilihan sel di coastal_backdrop.gd dan coastal_platform_art.gd.

Tidak perlu membuat physics layer pada TileSet visual ini, karena akan
menduplikasi collision yang dibangun generator.

## 3. Mengurangi/merapikan pijakan naik

Klik dua kali `Assets/Tileset/coastal_style.tres` di FileSystem:

| Properti | Default | Efek |
| --- | --- | --- |
| Climb Rise | 40 | Jarak vertikal maksimal. Lebih kecil = lebih banyak pijakan |
| Climb Width | 96 | Lebar pijakan zigzag |
| Climb Offset | 32 | Pergeseran kiri/kanan dari tengah shaft |
| Background Tint | warna gelap | Tingkat terang latar |

Pijakan dibagi rata sepanjang shaft; ujungnya tidak memiliki anak tangga kecil
sisa pembagian. Transisi masuk dan penangkap bawah sengaja lebih lebar.
40 px merupakan batas aman yang diuji untuk jump_force 300 dan gravity 1000.
Jangan menaikkan jarak melebihi 40 lewat teks resource tanpa mengubah kemampuan
karakter dan menguji ulang. Jumlah pijakan turun dibanding versi 32 px, tetapi
shaft tinggi tetap memerlukan beberapa lompatan.

## 4. Mengisi platform per room

1. Buka `coastal_template_preview.tscn` atau `coastal_practice_preview.tscn`.
2. Pilih node root, klik resource Template. Bagian **Interior Platforms**:
   - **Automatic Balconies**: menambahkan pijakan awal dan balkon samping,
     termasuk pada room vertikal. Area kosong dan ruang kepala diperiksa.
   - **Extra Platforms**: Array Rect2 untuk platform tambahan buatanmu.
3. `Position` adalah pojok kiri atas relatif terhadap room; Y bertambah ke bawah.
   `Size.x` adalah lebar, `Size.y` harus 8. Preview menampilkan platform dan tile.
4. **Preview Up Socket / Preview Down Socket** pada node root hanya menyimulasikan
   socket yang terpakai. Generator memilih socket sebenarnya saat menyusun level.
5. Simpan resource, jalankan ulang level, lalu tekan M untuk mengecek hasil fisik.

Contoh room 512 x 320: `coastal_practice.tres` sudah memakai platform manual
dengan Automatic Balconies mati. Contoh balkon kanan:
`Position = (368, 224)`, `Size = (112, 8)`.
Ubah lebarnya menjadi 80 untuk memperpendek. Pada contoh ini, balkon ada 96 px
di atas lantai dan dapat dicapai melalui pijakan bawahnya.

Aturan supaya jalur utama tetap terbuka:

- Platform biasa minimal 64 px di atas lantai, lebar minimal 24, tinggi 8.
- Hindari kolom tengah: tepi kiri platform kanan >= lebar/2 + 112;
  tepi kanan platform kiri <= lebar/2 - 112.
- Pijakan awal 32 px di atas lantai hanya diperbolehkan di area x=0..24
  atau x=lebar-56..lebar-24, agar tidak menimpa spawn/reward/pintu.
- Sisakan ruang kepala 32 px. Semua bagian harus berada di air_regions.
- Atur beda tinggi <= 40 px dan beri pijakan penghubung. Validasi bentuk tidak
  otomatis membuktikan semua susunan manual bisa dilompati: jalankan tes fisika.

Template latihan belum dimasukkan ke catalog. Tambahkan ke Room Templates pada
`Templates/catalog.tres` jika ingin dipakai generator. Jangan mengecat collision
di scene preview untuk mengubah PCG; edit resource Template.

## Pemeriksaan setelah edit

Dari folder proyek, contoh (ganti Godot dengan lokasi executable):

```text
Godot --headless --fixed-fps 60 --path . --log-file test.log --script Tests/test_coastal_round_trip.gd
```

Jalankan juga `test_coastal_layout.gd`, `test_coastal_treasure_physics.gd`,
`test_coastal_balconies.gd`, `test_room_exit.gd`, dan `test_coastal_map.gd`.
Tes balkon menempuh rantai platform samping dari bawah ke atas; template dengan
jalur khusus bisa memerlukan rute uji khusus. Tes finite seed bukan bukti untuk
seluruh kemungkinan modifikasi.

Referensi UI Godot: https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html

## Dekorasi manual per template room

Buka scene di `Scenes/Rooms/Stage/Coastal/Decorations/`, misalnya
`tidal_hall.tscn` atau `reef_tower.tscn`. Setiap template katalog sudah terhubung
ke scene bernama sama melalui properti **Manual Decorations > Decoration Scene**.

1. Pilih node `Decorations` pada scene tersebut.
2. Tarik `Scenes/Environment/pillar.tscn`, `coral.tscn`, atau scene dekorasi
   buatanmu dari FileSystem ke node itu.
3. Geser, putar, ubah Scale, atau duplikat instance di editor 2D, lalu Ctrl+S.
4. Jalankan `Levels/room_1_preview.tscn` (F6 setelah membuka scene preview).
   Generator memakai dekorasi itu setiap kali template terkait dipilih.
   Tidak semua template selalu muncul dalam setiap seed.

`RoomGuide` hanya panduan editor: kotak adalah batas room, lingkaran/pita hijau
adalah socket, garis pijakan menunjukkan perkiraan platform. Socket atas/bawah
preview bisa diubah di Inspector; pemakaian sebenarnya ditentukan generator.
Panduan disembunyikan saat gameplay. Jangan taruh dekorasi di dalam RoomGuide.
Koordinat (0,0) adalah pojok kiri atas room, lantai ada di y = tinggi room.
Contoh pilar memakai scale 0.4; sprite centered harus dinaikkan setengah tinggi
visualnya agar kaki menyentuh lantai. Hindari menutupi pintu dan pijakan.

Dekorasi manual dirender di belakang player, di depan backdrop. Pakai Sprite2D
atau Node2D tanpa collision untuk ornamen. Layout/collision tetap di resource
Templates/*.tres. Memindahkan gambar tidak memindahkan lantai fisik.

`Automatic Decorations` dimatikan untuk template yang sudah disiapkan sehingga
ornamen otomatis tidak menumpuk dengan susunan manual. Bisa diaktifkan kembali
jika ingin keduanya. Template `coastal_practice` juga punya scene dekorasi, tetapi
belum masuk katalog sehingga tidak muncul pada run acak.

Scene dekorasi menggunakan path string untuk menghindari siklus resource dengan
RoomGuide. Kalau file scene dipindah/diubah namanya, perbarui Decoration Scene
pada resource template. Jangan arahkan properti ini ke scene stage/gameplay.

## Melukis lantai manual (FloorTiles)

Buka `Scenes/Rooms/Stage/Coastal/Decorations/<nama_template>.tscn`, pilih
`FloorTiles`, lalu panel TileMap di bawah editor. Pilih atlas source **Tengah A**
atau **Tengah B**, pilih tile tunggalnya, lalu lukis di baris lantai yang sudah
tersedia. Source **Ujung kiri** dan **Ujung kanan** untuk ujung, bukan bagian tengah.
Simpan Ctrl+S dan jalankan `Levels/room_1_preview.tscn`.

Layer memakai tile sumber 64px dengan scale 0.25 agar sel gameplay tetap 16px.
Jangan ubah transform FloorTiles: posisi Y sama dengan tinggi room. Lukis pada
baris lokal y=0; ini pengganti visual lantai bawah saja, bukan editor platform
atau collision. Tile di luar lantai fisik dibuang pada instance runtime.
Menghapus tile menyembunyikan gambarnya, tetapi tidak menghapus collision.
Pintu bawah dibuka otomatis sesuai socket yang digunakan generator; file sumber
lukisanmu tetap utuh. Pijakan naik dan lantai koridor masih dibuat otomatis.

Properti template **Manual Floor** mengaktifkan pengganti visual ini. Seluruh
scene template yang tersedia sudah mendapat FloorTiles dan Manual Floor aktif.
Susunan dekorasi yang sudah ada tetap dipertahankan. RoomGuide hanya panduan.

Update batas room: dinding samping dan plafon kembali digambar menggunakan bagian batu dari tileset pantai.png. Background parallax tetap terlihat di ruang kosong; FloorTiles manual dan lubang socket tetap dipertahankan.

## Blok di balik pembatas: WallTiles

Setiap scene `Coastal/Decorations/*.tscn` punya `WallTiles`. Layer ini mengisi
kantong padat di luar air_regions dan sabuk 192px di luar batas template.
Pilih WallTiles > panel TileMap > source Batu isi, lalu lukis/hapus blok.
Ctrl+S; hasil dipakai ketika template muncul pada stage 1. Jangan ubah transform
layer (scale 0.25, posisi 0,0); satu sel menjadi 16px di gameplay.

WallTiles hanya isi visual di belakang pembatas. Collision dan permukaan batas
masih dibuat generator. Menghapus blok tidak membuka jalan baru. Saat runtime,
blok di jalur player, sambungan antar-room, atau lapisan shell dibuang hanya
pada instance sehingga pintu tidak tertutup; lukisan di file sumber tetap utuh.
FloorTiles dan dekorasi manual tetap independen. Jika blok dua template bertumpuk
di luar room, edit kedua template untuk mengosongkan bagian tersebut.

## Pilihan tile sesuai kelompok aset

Palette FloorTiles dan WallTiles sekarang berisi Surface (8 pilihan),
Isi - batu retak, Platform (6 pilihan), serta Sudut dalam kiri/kanan.
Pilih source Sudut dalam di panel TileMap; alternatif 0..7 menyediakan kombinasi
flip horizontal, vertikal, dan transpose (rotasi/arah lainnya). Pilih alternatif
lalu lukis. Semua gambar tetap berasal dari tileset pantai.png.
ID lama 0..4 dipertahankan agar lukisan tidak hilang; ID 4 kini batu retak.
Platform procedural memakai ujung kiri/kanan serta empat variasi tengah.

Palette platform dan sudut tersedia untuk mengganti tampilan sel yang diizinkan
layer tersebut. FloorTiles tetap khusus baris lantai bawah dan WallTiles untuk
area padat; ini belum mengubah keduanya menjadi editor collision/platform bebas.

## Sudut otomatis

Backdrop/AutomaticCorners memasang ornamen sudut dalam dari tileset pantai
setelah semua room dan koridor tersambung. Tile dibalik horizontal/vertikal untuk
pertemuan dinding kiri/kanan dengan lantai/plafon. Deteksi memakai area playable
final, sehingga pintu terbuka tidak dianggap dinding. Ornamen 16px ini visual
saja, berada di sisi dalam pertemuan dinding; tidak menambah collision atau
mengubah lukisan FloorTiles/WallTiles. Sudut luar tetap mengikuti shell batu.

## Atlas rapi (aktif)

Sekarang pilih source **Pantai - atlas 64px** pada FloorTiles / WallTiles.
PNG: Assets/Tileset/Sprites/coastal_packed.png (512x384, 8 kolom x 6 baris).
TileSet: Assets/Tileset/coastal_packed.tres. Texture Region Size 64x64,
Margins 0, Separation 0. Scale layer tetap 0.25. Semua potongan masuk utuh;
platform berada di bagian atas sel transparan dengan tinggi maksimal 32px.

Baris dari atas: surface; dinding/isi/sudut; dasar/ornamen; platform;
tangga/lereng; pasir. Pilih tile langsung pada atlas lalu lukis, tidak perlu
menambahkan PNG asli lagi. Semua tile punya alternatif flip/transpose.
Source custom di luar palette lama dipertahankan. Source atlas lama 0..16
sudah dipetakan ke koordinat atlas baru; posisi lukisan dan dekorasi tetap.
Jika Godot meminta reload scene yang berubah di disk, reload untuk melihat
atlas baru. Simpan perubahan editor yang belum disimpan ke salinan scene
terlebih dahulu agar tidak tertimpa.

Tools/pack_coastal_atlas.gd mereproduksi PNG dari gambar asli tanpa menggambar
ulang. Tools/migrate_coastal_packed.gd adalah migrasi satu kali, jangan dijalankan
ulang pada scene yang sudah bermigrasi. Skrip setup/palette lama untuk atlas
sebelumnya tidak perlu dijalankan lagi.
