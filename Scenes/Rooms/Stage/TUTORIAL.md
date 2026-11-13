# Mengedit ruangan tutorial

- Buka `res://Scenes/Rooms/Stage/tutorial_room.tscn` untuk mengedit isi ruangan. Ini sumber ruangan awal setelah lobby, tanpa pemilihan varian acak.
- Buka `res://Levels/tutorial_preview.tscn`, lalu F6 untuk bermain dari tutorial. Ruangan yang terlihat di preview diganti saat runtime dengan instance terbaru dari sumber yang sama. Edit isi di `tutorial_room.tscn`, bukan override instance di preview.
- `Floor`, `Ceiling`, `Left`, dan `Right`: ubah `Visual` dan collision `Shape` bersama-sama agar gambar sesuai batas fisik.
- `PlayerSpawn`: posisi awal pemain. `DoorSpawns/Marker0`: posisi pintu menuju Room 1. Pintu dibuat saat game berjalan.
- Pertahankan `PlayerSpawn`, `RewardSpawn`, `DoorSpawns`, dan `EnemySpawns`. Validator saat ini mengharuskan marker di y=350 dan x=40 sampai 792. Pertahankan lantai y=384 untuk layout awal ini.
- Tambahkan dekorasi, platform, dan Label petunjuk sebagai node biasa. `Title` dapat diganti tanpa ditimpa oleh stage.
- `NPC` adalah Semar. Pemain mendekat lalu menekan E untuk memulai dialog. Nama NPC dan daftar instruksi dapat diedit pada root TutorialRoom di Inspector.
- `TutorialUI/Dialogue` adalah textbox dengan panel dari bestiary dan font Silkscreen. Aktifkan Visible sementara untuk menata textbox di editor; script menyembunyikannya saat mulai bermain.
- Setelah seluruh dialog selesai, Aul muncul di `HostileSpawn`. Ubah posisi marker ini untuk mengatur tempat latihan. `EnemySpawns` tetap kosong supaya tidak ada musuh sebelum dialog.
- Gate menampilkan pesan untuk berinteraksi dengan Semar jika tutorial belum dimulai, lalu meminta penyelesaian latihan sampai Aul dikalahkan. Setelah Aul kalah, pemain wajib kembali berinteraksi dengan Semar dan menyelesaikan dialog laporan sebelum gate menuju Room 1 terbuka.
- Restart mengulang tutorial dari awal. Posisi marker HostileSpawn mengikuti batas validator yang sama dengan marker lainnya.
- Efek `SeaMist` digambar saat runtime. Lantai, dinding, latar dasar, dan teks bisa diedit di editor.

Alur: lobby → tutorial → Room 1 → Room 2 → Room 3 → Elite → Room 4 → Room 5 → Room 6 → Boss.

Textbox menggunakan PanelContainer dengan panel bestiary, MarginContainer, dan VBoxContainer. Saat bermain, posisinya mengikuti kepala Semar dalam koordinat layar dan dijaga di dalam viewport. Teks laporan dapat diedit lewat Report Text pada root TutorialRoom.

