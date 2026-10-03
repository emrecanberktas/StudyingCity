# Studying City

Odaklanma/ders çalışma zamanlayıcısı + şehir kurma oyunu. Godot 4.3, GDScript, dikey (720x1280) mobil ekran.
Tasarım: [docs/PLAN.md](docs/PLAN.md). Ekran görüntüleri: `docs/screenshots/`.

## Çalıştırma
Godot 4.3+ ile `project.godot` dosyasını açıp F5. Debug derlemede 1 dakikalık test süresi seçilebilir.

## Testler
```
godot --headless --path . -s res://tests/test_game_state.gd
godot --headless --path . -s res://tests/test_power_saver.gd
```

## Yapı
- `scripts/game_state.gd` — autoload: coin, envanter, şehir, seans, odak kuralı, kayıt
- `scripts/buildings.gd` — bina kataloğu (fiyat, renk, yükseklik)
- `scripts/main.gd` — arayüz (kodla kuruluyor), mağaza ve sonuç pencereleri
- `scripts/map_view.gd` — izometrik şehir haritası: kaydırma, yakınlaştırma, bina taşıma
- `scripts/worker_art.gd` — inşaat işçilerinin çizimi ve animasyon pozları
- `scripts/building_art.gd` — binaların çizimleri (çatı, pencere, tente, ağaç, saat)
- `scripts/build_site.gd` — inşaat alanı ve işçi animasyonu
- `scripts/power_saver.gd` — pil tasarrufu: FPS sınırları ve eko mod (siyah ekran)
- `scripts/iso.gd` — izometrik çizim yardımcıları

## Android APK
`export_presets.cfg` içinde hazır bir Android preset'i var. Godot 4.3 export şablonları, Android SDK (build-tools içinde `apksigner`) ve bir debug keystore ile:
```
godot --headless --path . --export-debug "Android" build/StudyingCity.apk
```
Keystore ortam değişkenleriyle verilebilir: `GODOT_ANDROID_KEYSTORE_DEBUG_PATH`, `GODOT_ANDROID_KEYSTORE_DEBUG_USER`, `GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD`.
iOS için macOS + Xcode gerekir, preset'i henüz yok.
