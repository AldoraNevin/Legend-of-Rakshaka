# Stage coastal

Stage aktif: Lobby -> Safe -> Room 1-3 -> Elite -> Room 4-6 -> Boss.
Room combat memakai `Scenes/Rooms/Stage/coastal_room.tscn`.

Generator coastal sekarang memakai template Resource dan socket empat arah,
penempatan 2D dengan backtracking, serta peta M dari geometri aktual.
Dokumentasi aktif dan cara menambah template ada di [coastal-graph.md](coastal-graph.md).

Scene modul coastal/kastil lama tetap tersedia sebagai aset referensi; aturan
grid tiga tingkat, arus teleport dan profil geometri lama tidak lagi menjadi
pembangun room combat aktif. Visual masih berupa prototipe geometri pesisir.
