# Sukma, pemulihan, dan upgrade
Skill: R atau tap ikon di bawah HP. Memulihkan 10 HP, tanpa melebihi HP maksimum.
HP penuh, mati, dialog yang membekukan pemain, atau pause tidak memakai charge.
Awal 1 charge. Recharge satu per satu: 30 detik waktu bermain. Jeda penggunaan 3 detik.
Charge dan timer tersimpan di slot aktif. Idle 6 frame, masing-masing 0,1 detik.

Upgrade:
- max_life: +5 HP/level, 8 level, bonus maksimum 40 HP.
- sword: +5% damage/level, 8 level, bonus maksimum 40%.
- skill_charge: +1 kapasitas/level, 4 level, total maksimum 5 charge.
- skill_cooldown: -5% dari 30 detik/level, 8 level, minimum 18 detik.
Biaya = biaya dasar x (level + 1); dasar 3, 4, 6, 5 Sukma.
Bonus HP artefak ditambahkan di atas upgrade. Damage/health musuh menyimpan pecahan.
Save lama: level max_life/sword dipertahankan, speed menjadi skill_charge,
jump menjadi skill_cooldown. Save tanpa data skill mulai dengan kapasitas penuh.
Menu memakai Upgrade_menu; level memilih frame cincin pada ikon.
Area exit map terbuka dalam radius penglihatan tanpa membuka seluruh jalur.
Tes: test_sukma_skill_upgrades.gd dan test_map_fog.gd.
