# Mengedit Bestiary di Godot

- `bestiary_catalog.tscn`: penghubung tab dan interaksi lobby.
- `bestiary_enemies_tab.tscn`: buku Musuh, seluruh kartu musuh/boss, dan panel detailnya.
- `bestiary_artifacts_tab.tscn`: buku Artefak, seluruh kartu artefak, dan panel detailnya.

Buka scene tab secara langsung. Di `Book/EntryGrid`, setiap `Entry_<id>` adalah
entri permanen, bukan slot yang digunakan ulang untuk entri lain.

1. Ubah nama melalui `Entry_<id>/NameLabel → Text`.
2. Ubah gambar melalui `Entry_<id>/Portrait → Texture`.
3. Pilih `Entry_<id>` untuk mengedit Region, Category, Description, History,
   Attack Pattern, Tactics, HP, dan Attack di Inspector.
4. Edit posisi/ukuran panel dan tombol di bawah `Book`. Grid mengatur posisi
   kartu melalui Columns, Separation, dan Custom Minimum Size kartu.
5. Root tab → Preview Entry memilih entri detail dan halaman yang ditampilkan
   di editor (nomor mulai dari 0). F6 pada tab menggunakan pilihan yang sama.

F6 menampilkan semua isi untuk preview, tanpa mengubah save pemain. Untuk
menguji kunci penemuan pada F6, matikan `Preview All When Run Alone`. Saat
dibuka melalui lobby, status penemuan tetap mengikuti save, sedangkan nama,
gambar, dan isi catatan tetap diambil dari scene.

Jangan ubah Entity ID untuk entri yang sudah ada: ID menghubungkannya dengan
progres penemuan. Data tampilan tidak lagi ditimpa oleh `bestiary_data.json`.
File JSON masih digunakan oleh sistem gameplay/save untuk daftar ID master.
Untuk entri baru yang bisa ditemukan, tambahkan ID yang sama pada data master
dan pemanggilan discovery gameplay.

Setiap tab memiliki tema/tampilan sendiri. Untuk mengatur posisi Book secara
manual saat runtime, matikan `Auto Fit Book` pada root tab.
