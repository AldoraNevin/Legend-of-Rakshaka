# Rancangan Room-Based Legend of Rakshaka

Untuk tahap awal, struktur level paling aman adalah model Hades-like: pemain masuk ke satu room aktif, menyelesaikan combat, mengambil reward, lalu memilih pintu untuk pindah ke room berikutnya. Room berikutnya dipilih random dari template yang sudah kamu buat.

## Flow Utama

```text
LOBBY
  |
  v
ROOM 1 -> pilih pintu -> ROOM 2 -> pilih pintu -> ROOM 3 -> ... -> BOSS
```

Generator di `Script/level_2_generator.gd` sekarang memakai flow Hades-like:

```text
Masuk room
  |
  v
Combat terkunci
  |
  v
Semua musuh mati
  |
  v
Reward muncul
  |
  v
Reward diambil
  |
  v
Pilih pintu berikutnya
```

Untuk fallback sementara, generator masih bisa membuat room sederhana sendiri. Untuk versi final, isi `room_templates` dan `boss_room_templates` di Inspector dengan scene room manual buatanmu.

## Struktur Scene Room Manual

Supaya room manual bisa dibaca oleh sistem, buat scene `Node2D` dengan node opsional berikut:

```text
Room_Combat_A
├── TileMap / StaticBody2D / dekorasi bebas
├── PlayerSpawn      (Marker2D)
├── RewardSpawn      (Marker2D)
├── EnemySpawns      (Node2D)
│   ├── EnemySpawn1  (Marker2D)
│   └── EnemySpawn2  (Marker2D)
├── SpikeSpawns      (Node2D)
│   └── SpikeSpawn1  (Marker2D)
└── DoorSpawns       (Node2D)
	├── DoorSpawn1   (Marker2D)
	├── DoorSpawn2   (Marker2D)
	└── DoorSpawn3   (Marker2D)
```

Yang wajib untuk enak dipakai:

- `PlayerSpawn`: posisi player saat masuk room.
- `RewardSpawn`: posisi reward setelah musuh mati.
- `DoorSpawns`: posisi pilihan pintu setelah reward diambil.
- `EnemySpawns`: posisi spawn Kuntilanak sementara.

Kalau node-node itu belum ada, script tetap memakai posisi fallback.

Untuk musuh, ada dua cara:

- Pakai `EnemySpawns` supaya script otomatis spawn Kuntilanak.
- Taruh enemy langsung di scene room; selama enemy itu `CharacterBody2D` dan punya method `take_damage`, sistem akan ikut menghitungnya sebagai target combat.

## Tipe Room Desain

Untuk desain manual nanti, kamu bisa tetap membagi room seperti ini:

| Tipe Room | Fungsi | Isi Utama |
| --- | --- | --- |
| Combat | Tantangan biasa | Platform random, 1-2 Kuntilanak, coin |
| Platform | Traversal | Platform bertingkat, coin |
| Treasure | Reward | Platform tengah, coin lebih banyak |
| Trap | Risiko | Platform random, spike, coin |
| Elite | Tantangan sebelum boss | 2-3 Kuntilanak, spike, coin |
| Boss | Ruang akhir | Arena lebih lebar, 3-4 Kuntilanak, reward |

## Contoh Jalur Run

```text
┌────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌───────┐
│ START  │-->| COMBAT   │-->| TREASURE │-->| PLATFORM │-->| ELITE |
└────────┘   └──────────┘   └──────────┘   └──────────┘   └───┬───┘
															   |
															   v
														   ┌──────┐
														   │ BOSS │
														   └──────┘
```

Yang berubah setiap run:

- Template room yang dipilih.
- Door label atau arah pilihan.
- Jumlah dan posisi coin.
- Jumlah dan posisi enemy.
- Posisi dan panjang spike.

Yang tetap:

- Pemain harus menghabisi semua enemy dulu.
- Reward baru muncul setelah combat selesai.
- Pintu baru muncul setelah reward diambil.
- Room terakhir bisa diambil dari `boss_room_templates`.

## Catatan Implementasi

Ukuran fallback room adalah `34 x 18` tile. Dengan tile `16 px`, satu room kira-kira `544 x 288 px`. Saat kamu memakai template manual, ukuran room bisa kamu atur sendiri lewat isi scene room-nya.

Tahap berikutnya yang paling masuk akal:

1. Tambahkan visual label atau dekorasi khas biome untuk tiap room.
2. Ganti boss sementara dari beberapa Kuntilanak menjadi scene boss khusus.
3. Ganti reward coin sementara menjadi reward random sungguhan.
