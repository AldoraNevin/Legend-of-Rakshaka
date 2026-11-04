> Stage aktif sudah beralih ke tema pesisir bertingkat. Lihat [coastal_stage.md](coastal_stage.md). Detail modul kastil di bawah disimpan sebagai dokumentasi versi sebelumnya.

# Stage dan Room 1 modular

Urutan stage tetap: Lobby -> Safe -> Room 1 -> Room 2 -> Room 3 -> Elite -> Room 4 -> Room 5 -> Room 6 -> Boss.

## Menjalankan

- Levels/lobby.tscn + F6 untuk alur lengkap.
- Levels/room_1_preview.tscn + F6 untuk langsung Room 1.
- Atur seed di root Levels/stage_graph_template.tscn, Inspector > Run Flow > Random Seed: 0 untuk seed baru setiap run; angka lain untuk mengulang hasil.
- Preview mewarisi seed stage utama tanpa override. Run dari Lobby memakai pengaturan yang sama. Hindari mengubah Random Seed langsung pada preview karena akan membuat override baru.
- Seed aktual dan urutan modul dicetak di Output.

## Sistem modul Room 1

Script/Stage/castle_room_pcg.gd merakit 10 modul dari 13 jenis scene manual.
Pola: Entrance -> 2 modul permukaan -> Descent -> 2 modul underground -> Ascent
-> 1 modul permukaan -> Ascent -> Exit. Pilihan permukaan diambil tanpa pengulangan
dari gallery, crypt, balcony, library, ruins, bridge. Pilihan underground diambil
tanpa pengulangan dari underground, sewer, dungeon. Urutan pilihan mengikuti seed.
Jalur masih linear tanpa loop/cabang. Underground benar-benar 128 px lebih rendah
setelah Descent; lalu pemain kembali naik. Terdapat 5 musuh per room.

Scenes/Rooms/Stage/Modules berisi tiga belas scene yang bisa diedit di editor:

- entrance.tscn: aula masuk.
- gallery.tscn: arena lebar dengan dua balkon.
- crypt.tscn: arena pendek dengan platform bertingkat.
- balcony.tscn: lorong balkon.
- ascent.tscn: modul naik 128 px dengan empat undakan 32 px.
- descent.tscn: modul turun 128 px.
- exit.tscn: ruang reward dan pintu Room 2.

room_1_castle.tscn sekarang hanya wadah generator; buka scene Modules untuk mengedit geometri, atau room_1_preview untuk bermain. Semua modul memakai grid, trim ungu, dan lengkungan dekoratif. Platform di setiap modul tidak berubah saat seed berubah. Lima musuh berada di modul combat; reward dan exit mengikuti posisi modul terakhir.

## Kontrak modul dan validasi

Root Node2D memiliki metadata module_id/width. Entry/Exit adalah Marker2D pada permukaan lantai: Entry.x=0, Exit.x=width. MainPath berisi StaticBody2D dalam urutan kiri-ke-kanan dengan Shape RectangleShape2D. Collision layer=2. Jangan memutar atau men-scale collider. Platforms berisi balkon opsional; Shell berisi langit-langit.

Validator memeriksa jenis/jumlah modul, socket yang bertemu tepat, lebar, urutan geometri, lantai bersebelahan, pijakan >=48 px, dan perubahan ketinggian <=32 px. Interval x tiap modul terpisah sehingga ruang tidak bertumpuk. Marker gameplay dicek dalam bounds, tidak tertanam dalam rectangle, dan memiliki lantai di bawahnya. Menambah penghalang pada Platforms/Shell tetap memerlukan tes fisika/playtest; validator bukan solver gerak umum.

## Tes

Jalankan Godot --headless --path . --script diikuti salah satu:

- res://Tests/test_castle_pcg.gd: 200 seed, variasi urutan, determinisme, socket rusak, rute rusak, regenerasi.
- res://Tests/test_castle_physics.gd: sambungan dan tangga pada empat seed (termasuk modul turun) dengan collider/kecepatan/gravitasi dasar pemain. Tiap perpindahan diuji terpisah tanpa combat.
- res://Tests/test_stage_graph.gd: urutan stage dan kontrak template.

Kemampuan dasar cukup untuk jalur utama; balkon opsional dapat memakai double jump. Combat dan kenyamanan visual tetap perlu playtest.


## Seed Room 1-6

Semua node combat (Room 1, 2, 3, 4, 5, 6) memakai modul kastil yang sama.
Safe, Elite, dan Boss tetap memakai template khusus. Seed combat diturunkan dari
seed utama aktual + nomor room combat * 1000003 (dibatasi ke integer positif).
Nomor room combat tidak menghitung Elite. Keenam seed berbeda dan tetap sama
saat seed utama diulang. Seed berbeda masih dapat memilih urutan modul sama.
Preview tetap mewarisi seed utama dan menghasilkan Room 1 yang sama dengan run
normal untuk seed nonzero. Pada seed utama 0, setiap run memilih seed utama baru.
Output menampilkan seed utama, seed room, dan urutan modul.
Tes tambahan: res://Tests/test_combat_room_seeds.gd.

## Modul diperpanjang

Lebar saat ini: Entrance 768, Gallery 1024, Crypt 768, Balcony 896,
Ascent 896, Descent 896, Exit 768 piksel. Semua modul memiliki platform tambahan
serta dekorasi banner/obor. Undakan utama Ascent/Descent tetap berbeda tinggi
32 px. Reward dan pintu ditempatkan relatif terhadap ujung Exit yang baru.
Perubahan ini berlaku pada semua Room 1-6; jumlah musuh sekarang lima per room.


## Modul tema tambahan

- underground.tscn: gua dengan stalaktit dekoratif dan pijakan batu.
- sewer.tscn: saluran air, pipa dekoratif, kanal hijau di bawah lantai.
- dungeon.tscn: penjara berjeruji dan balkon bertingkat.
- library.tscn: rak buku dan platform arsip bertingkat.
- ruins.tscn: pilar patah dan teras batu.
- bridge.tscn: lorong jembatan berwarna biru dengan platform atas.

Air dan dekorasi tidak memberi damage. Tema memakai geometri sederhana, belum
aset ilustrasi final. Semua module dapat diedit sebagai scene Godot. Pengujian
fisika menguji jalur utama; platform opsional dan combat perlu playtest.
