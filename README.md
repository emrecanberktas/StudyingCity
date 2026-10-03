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
- `scripts/map_view.gd` — izometrik şehir haritası
- `scripts/build_site.gd` — inşaat alanı ve işçi animasyonu
- `scripts/power_saver.gd` — pil tasarrufu: FPS sınırları ve eko mod (siyah ekran)
- `scripts/iso.gd` — izometrik çizim yardımcıları

## Mobil export
Godot'ta Proje > Export ile Android (Android SDK + export şablonları) veya iOS (macOS + Xcode) hedefi eklenir. Henüz export preset'i yok.
