# Tutorial dan audio
Slot baru mengunci serang dan dash. Halaman DialoguePages/Introduction/Combat
membuka kedua kemampuan, lalu menyimpannya. Menyelesaikan dialog laporan kepada
Semar setelah mengalahkan Aul menyimpan tutorial_completed.

Load checkpoint tutorial yang sudah selesai dialihkan ke Room 1. Masuk stage
dari lobby juga melewati tutorial jika slot aktif sudah selesai. Save lama
tanpa flag tutorial yang telah mencapai room_id > 0 dianggap selesai.
Save lama di lobby/tutorial tanpa flag tidak dapat menunjukkan apakah tutorial
pernah diselesaikan, sehingga tetap menjalani tutorial.

Script/Audio/game_audio.gd berisi daftar musik dan SFX dari SFX dan BGM FIX.
Lobby memilih lagu acak, tutorial memakai pilihan lobby terakhir. Room stage
memilih musik dari Stage randomize. Lagu berikutnya dipilih ketika lagu selesai,
tanpa mengulang langsung pilihan sebelumnya. Semua musik memakai bus Music.
Tebasan memakai satu dari tiga SFX slash; dash memakai dash.ogg pada bus SFX.

Tests/test_tutorial_progress.gd menguji kunci kemampuan, proses belajar, save,
Load melewati tutorial, isolasi slot baru, migrasi save lama, kembali dari lobby,
serta pemilihan stream musik/SFX.
