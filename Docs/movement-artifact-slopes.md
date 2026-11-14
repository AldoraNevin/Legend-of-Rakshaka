# Single jump, Selendang Bidadari, dan tanjakan

- Player mulai dengan satu lompatan. Berjalan keluar dari tepi platform tidak
  memberikan lompatan udara gratis.
- Selendang Bidadari (`selendang_bidadari`) membuka double jump. Nama maupun ID
  pada data `discovered_artifacts` dikenali. Artefak lain tidak membuka kemampuan ini.
- Penemuan artefak tersimpan melalui sistem save yang sudah ada. Save lama yang
  sudah menemukan Selendang juga langsung membuka kemampuan tersebut.
- Properti `Double Jump Artifact Id` di player dapat diganti. Nilai kosong
  mengunci double jump. Upgrade kekuatan lompat tidak membuka lompatan kedua.
- Wall jump tetap tersedia, dengan batas dua wall jump sebelum menyentuh lantai.
  Deteksi memakai ray dan normal kontak dinding untuk mendukung ukuran collider player.
- Atlas pantai Solid, baris 4 kolom 0–7, sekarang memakai polygon tanjakan dari
  kontur gambar. Posisi, bentuk lukisan, dan isi scene room tidak diubah.
- Player memakai floor snap 6px dan sudut lantai maksimum 50 derajat.

## Validasi room manual

Pemeriksaan navigasi kini mengenali jatuh turun dan estimasi rute berbantuan
dinding, tanpa mengasumsikan double jump. Namun graph sel tetap perkiraan dan
tidak membuktikan seluruh lintasan fisika, terutama tanjakan serta wall jump.

`Strict Traversal Validation` pada settings default mati: perkiraan navigasi yang
tidak lengkap dicatat pada metadata `traversal_diagnostics`, bukan membatalkan
level. Aktifkan kembali jika ingin penolakan ketat. Pemeriksaan geometri, pintu,
collision, dan keamanan marker tetap aktif. Posisi marker boleh 16–48px di atas
pijakan, tidak harus tepat 32px.

Level yang berhasil dimuat belum tentu semua jalurnya bisa dimainkan. Room yang
memerlukan lompatan terlalu jauh atau tidak punya tempat menempel di dinding
tetap memerlukan evaluasi desain; menonaktifkan penolakan tidak menambah kemampuan.

Tes: `test_jump_artifact.gd`, `test_single_jump_physics.gd`, dan
`test_coastal_slopes.gd`. Tes terakhir mengecek collider tanjakan dengan raycast
fisika asli, bukan hanya tampilan texture.
