# Stage Pesisir Laut Selatan / Kerajaan Laut Gaib

Stage aktif memakai tema pesisir. Urutan Lobby -> Safe -> Room 1-3 -> Elite ->
Room 4-6 -> Boss tetap. Lobby yang sudah ada tidak dirombak. Safe, Elite, dan Boss
mendapat warna pesisir dan animasi kabut/laut; boss masih musuh placeholder.

Room 1-6 memakai Scenes/Rooms/Stage/coastal_room.tscn dan
Script/Stage/coastal_room_pcg.gd. Modul kastil lama tetap disimpan sebagai aset
legacy, tetapi tidak dipilih generator stage aktif.

## Bentuk map

Tiap room memiliki 3 tingkat dan 2 atau 3 modul per tingkat. Seed mengacak
urutan kunjungan ketiga lantai serta sisi masuk kiri/kanan: 12 kombinasi rute.
Contoh: tengah -> atas -> bawah, atas -> tengah -> bawah, bawah -> atas -> tengah.
Lintasan horizontal berbalik setelah tiap perpindahan vertikal. Jalur luar tetap bergantian di dua sisi. Selain itu ada dua shaft tengah
yang menghubungkan bawah-tengah dan tengah-atas sebagai jalur alternatif.
Shaft tengah berada di celah 160 px antarmodul, sehingga tidak menabrak
platform/atap prefab. Pada grid 3 kolom, masing-masing memilih salah satu dari
dua celah menggunakan seed; pada grid 2 kolom tersedia satu celah tengah.

Koneksi naik memakai pijakan one-way beda tinggi 32 px. Koneksi turun berupa
shaft terbuka dengan landing di lantai tujuan. Spawn, reward, dan exit mengikuti
lantai awal/akhir dan arah perjalanan. Turun satu atau dua tingkat tidak memberi
fall damage. Di landing shaft turun ada petunjuk [E] Arus balik: tekan E untuk kembali
ke lantai asal, sehingga musuh atau reward yang terlewat tetap dapat dijangkau.

## Modul / visual

Scenes/Rooms/Stage/Coastal: shore (pesisir), reef (karang), tide (pasang),
grotto (gua ombak), palace (keraton laut), shrine (altar samudra). Lebar 640 px,
lantai pada y=256 dengan collision 640x32 dan center (320,16) relatif lantai.
Warna laut gelap/hijau kebiruan, garis ombak bergerak dan kabut. Visual masih
geometri/prototipe, belum ilustrasi final. Platform atas tetap manual per modul.

Tide dan Grotto memiliki hazard TidalSurge: siklus 8 detik, tanda kuning mulai
pada detik 4, semburan air detik 5.5-6.5, satu damage per siklus saat pemain
berada dalam area 144x40 px. Lompat, tunggu, atau gunakan platform. Ini hazard
lingkungan, belum serangan air khusus musuh/boss.

## Preview dan seed

Buka Levels/room_1_preview.tscn lalu F6. Seed diatur hanya pada root
Levels/stage_graph_template.tscn > Run Flow > Random Seed. 0 mengacak run baru;
angka tetap mengulang hasil. Seed masing-masing Room 1-6 diturunkan dari seed
utama. Preview mewarisi pengaturan ini.

## Validasi

Tests/test_coastal_layout.gd: 200 seed, grid 2/3 kolom, overlap, sambungan tangga,
dan ukuran lantai prefab. Tests/test_coastal_physics.gd: perpindahan pada jalur
utama untuk seluruh 12 pola memakai capsule/speed/gravity dasar; bukan playtest combat.
Tests/test_combat_room_seeds.gd: konsistensi seed enam room.

Tes collision menguji tiap transisi secara terpisah. Balkon opsional, wall-cling,
hazard, dan kenyamanan visual tetap perlu playtest langsung.


## Penghubung tengah

Lompati pijakan di shaft tengah untuk naik secara fisik. Jembatan one-way di
setiap lantai menjaga lintasan horizontal tetap tersambung. Di dekat tulisan
ARUS TENGAH, tahan panah atas + E untuk naik, atau panah bawah + E untuk turun.
Arus memindahkan pemain ke landing lantai sebelah, sehingga tidak perlu menembus
platform untuk turun. Tanpa tombol arah, E memilih salah satu koneksi terdekat
sesuai urutan; gunakan kombinasi arah untuk memilih secara pasti.

Jalur luar dan Arus balik tetap tersedia. Mengambil shortcut tidak menghilangkan
syarat membunuh semua musuh sebelum reward/pintu terbuka.

Tes tambahan: test_coastal_interior_physics.gd menguji tangga tengah pada dua
ukuran grid, test_coastal_currents.gd menguji interaksi kedua arah dan jaraknya.
