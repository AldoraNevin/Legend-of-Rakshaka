# Save game per slot

Start Game langsung membuka Load Game dengan tiga slot tetap. Klik Empty Save
untuk membuat progres baru di lobby; klik Load untuk melanjutkan slot terisi.
Tombol Hapus pada slot terisi meminta konfirmasi; Batal mempertahankan save.
Penghapusan mengosongkan slot dan backup-nya tanpa mengubah slot lain.
Slot terisi tidak ditimpa oleh pembuatan progres baru. Back kembali ke main menu.

Setiap slot menyimpan gold/coin, upgrade, skill, koleksi artefak dan hostile/bestiary,
HP, seed stage serta ruangan terakhir. Koleksi dipulihkan dari slot yang dipilih,
bukan digabung dengan koleksi slot lain. Save profil global lama tidak otomatis
memasukkan progres ke slot baru.

Gold dari coin dan peti, penemuan bestiary/artefak, pembelian upgrade, perpindahan
ruangan, Leave dari pause, serta penutupan aplikasi memicu penyimpanan.
`player_data.save_to_json()` meneruskan penyimpanan gameplay ke slot aktif.
Pickup gold baru harus memakai `player_data.add_gold(amount)`; penemuan memakai
`discover_enemy` / `discover_artifact`. Mutasi skill baru harus memanggil
`save_to_json()` setelah selesai. Menjalankan scene langsung dari editor tanpa
memilih slot tidak menimpa save mana pun.

Load menempatkan pemain di pintu masuk ruangan terakhir dengan resource terbaru.
Musuh, pickup dan pintu dibangun ulang; posisi persis dan keadaan pertarungan
bukan bagian snapshot. Upgrade diterapkan kembali pada statistik pemain.
Kembali ke lobby tidak menghapus penanda ruangan terakhir; memasuki perjalanan
baru memperbaruinya. Artefak yang disimpan adalah progres koleksi yang tersedia
pada `player_data`; sistem inventori/effect artefak aktif belum tersedia.

Autoload `CheckpointManager` menyimpan versi 2 dengan tiga elemen `slots` di
`user://room_checkpoints.json`. Slot kosong bernilai null. File `.tmp` diverifikasi
sebelum mengganti file utama, dan `.bak` menyediakan pemulihan. File rusak tidak
dianggap slot kosong. Format versi 1 tetap dibaca: tiga checkpoint lama menjadi
tiga slot dengan urutan yang sama dan dikonversi saat penulisan berikutnya.
Validasi kompatibilitas generator/scene masih berlaku pada checkpoint stage.

UI permanen: `Scenes/UI/load_game_menu.tscn`; pengisian teks dan aksi slot:
`Script/UI/load_game_menu.gd`. Adapter generator: `Script/Save/room_checkpoint_adapter.gd`.

## Verifikasi

`Tests/test_checkpoints.gd` memakai file terpisah untuk menguji pembuatan slot,
isolasi koleksi, autosave gold/upgrade, pergantian ruangan, pemuatan seed dan
resource terbaru, Leave, sesi baru, serta recovery backup. Tes tidak menimpa
save pemain. `Tests/test_checkpoint_menu.gd` menguji Start Game langsung membuka
slot kosong yang dapat diklik dan Back kembali ke menu utama.
