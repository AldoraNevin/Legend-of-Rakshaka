# Portal dalam level modular

Portal hanya muncul di ruang peti, artefak, dan exit. Tidak ada portal pintu masuk atau percabangan.
Semua portal awalnya terkunci sampai didekati.
Portal exit memakai RewardSpawn ruang exit agar tidak menyentuh trigger pindah stage.
Dekati portal (60 unit, selisih tinggi maksimal 35) untuk mengaktifkannya.
Tekan F atau tombol Portal di layar untuk membuka peta; klik/tap lingkaran portal biru yang sudah ditemukan.
Portal asal berwarna kuning dan tidak bisa dipilih. Fog of war tetap ditampilkan. Tombol Kembali/Esc menutup menu. E/Aksi tetap untuk reward.

Teleport mengubah posisi pemain dan mereset kecepatan; tidak memuat ulang scene,
memberi reward, menyembuhkan, membuka exit, atau mereset musuh. Level dijeda saat
memilih tujuan dan kamera diposisikan ulang setelah teleport. Portal yang terbuka
juga diberi penanda di peta pada area yang sudah dijelajahi.

Jaringan ini berlaku di dalam level modular aktif. Portal yang ditemukan dan sel fog of war
yang terbuka tersimpan per slot untuk ruangan checkpoint aktif. Perubahan diperiksa setiap
0,5 detik dan juga disimpan bersama progress saat keluar. Load memulihkan keduanya
setelah ruangan dibangun dengan seed yang sama. Save lama tanpa data eksplorasi tetap
bisa dibuka, dengan peta belum dijelajahi. Ruangan baru mulai dengan eksplorasi baru.
Script: Script/Stage/Modular/portal_network.gd dan Script/Interactables/level_portal.gd.
Tes: Tests/test_level_portals.gd.

Tampilan portal memakai animasi Ghostly cyan firefly dari aset Main Menu (8 frame).
Label di dunia dan peta hanya "Portal"; ID internal tetap membedakan tujuan save.
