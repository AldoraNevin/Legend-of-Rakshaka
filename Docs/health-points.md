# HP karakter

HP penuh 100; 1-100 berarti hidup dan 0 memicu animasi kematian.
Damage dasar Aul 12, Kuntilanak 20, spike 15. Nilai dapat diatur lewat properti
export pada script/scene musuh. Serangan menggunakan player.take_damage(),
termasuk spike, sehingga dash dan invulnerability setelah hit tetap berlaku.
Damage pedang dan HP musuh tetap memakai balancing sebelumnya.

Vitalitas tetap memiliki tiga level. Setiap level mengurangi damage masuk 5%
(maksimal 15%), dibulatkan ke integer dengan minimum 1 untuk serangan positif.
Pembelian Vitalitas memulihkan HP tanpa menaikkan batas 100.

HUD memakai atlas dari Assets/Legend of Rakshaka/UI HUD/HP and mana HUD.png,
dengan frame, fill merah, dan ikon hati pada Scenes/UI/health_hud.tscn.
Bagian mana disimpan dalam aset sumber, tetapi belum ditampilkan karena gameplay
belum mempunyai resource mana. HUD diinstansiasi oleh Script/UI/gui.gd untuk
lobby dan stage tanpa mengubah scene/generator atau signature checkpoint.

Snapshot pemain baru menyimpan health_version=2. Save lama tanpa penanda itu
mengonversi rasio life/max_life ke 100 saat dimuat. Level upgrade dan koleksi
lain tetap dipertahankan. Save berikutnya memakai nilai HP baru.

Tests/test_health_points.gd memeriksa damage, invulnerability, spike, Vitalitas,
HUD, konversi save, dan kematian. Tests/test_checkpoints.gd menguji save/load
progres melalui scene lobby dan stage sebenarnya.
