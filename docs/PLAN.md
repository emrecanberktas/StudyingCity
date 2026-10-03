# Studying City — Oyun Tasarım Planı (v0.1)

## Ana döngü
1. Envanterden bir bina seç, çalışma süresini ayarla (15–90 dk; debug derlemede 1 dk test seçeneği var).
2. "Çalışmaya Başla": inşaat ekranı açılır, minik işçiler tuğla taşır, bina süreyle birlikte yükselir.
3. Süre dolunca bina şehir haritasına eklenir, kullanıcı dakika başına 1 coin kazanır.
4. Coin'lerle mağazadan yeni bina alınır; alınan bina envantere girer ve inşa edilmesi için yeni bir seans gerekir.
5. Harita 3x3 başlar, dolunca her seferinde bir sıra büyür (4x4, 5x5...). Küçük bir alandan büyük şehre.

## Odak kuralı
- Sayaç duvar saatine göre çalışır; uygulama arka plana gitse de süre akar.
- Seans sırasında uygulamadan **15 saniyeden** uzun çıkılırsa seans başarısız olur (`BACKGROUND_GRACE_SEC`).
- Başarısız ya da "Vazgeç" ile biten seansta coin verilmez, bina kaybolmaz, envantere geri döner.
- Kullanıcı süre bitimine 15 sn'den az kala çıktıysa seans başarılı sayılır.
- Seans sırasında ekran açık tutulur (`screen_set_keep_on`).
- Açık karar: telefonu kilitlemek de "çıkmak" sayılıyor (Godot ikisini ayırt edemiyor). Daha yumuşak bir mod istenirse bina yıkılmak yerine sadece yavaşlayabilir.

## Pil tasarrufu
- Kare hızı sınırı: menüde 60 FPS (ekran zaten yalnızca bir şey değişince çizilir), seans sırasında 30 FPS.
- **Eko mod:** seans sırasında 15 sn ekrana dokunulmazsa ekran siyaha döner, yalnızca sönük sayaç kalır. İşçi animasyonu durur, oyun 2 FPS'e iner. OLED ekranlarda siyah pikseller kapalı olduğu için ekran tüketimi de düşer. Dokununca normale döner; uyandıran dokunuş düğmelere gitmez.
- Sayaç ve ilerleme çubuğu yalnızca görünen değer değişince güncellenir (saniyede bir / %0,5'te bir).
- Kayıt seans sırasında 10 sn'de bir yazılır.
- Ana ekrandaki "Pil tasarrufu: Açık/Kapalı" düğmesiyle eko mod kapatılabilir (FPS sınırları yine geçerli). Ayar kayıtta tutulur.
- Kod: `scripts/power_saver.gd`, testler: `tests/test_power_saver.gd`.

## Ekonomi (başlangıç değerleri)
| Bina | Fiyat | Not |
|---|---|---|
| Ev | 15 | Oyuna 1 tane bedava ile başlanır |
| Park | 25 | |
| Kafe | 30 | |
| Kütüphane | 60 | |
| Okul | 90 | |
| Saat Kulesi | 150 | |

Ödül: dakika başına 1 coin. 25 dk'lık bir seans = 25 coin. Değerler `scripts/buildings.gd` ve `GameState.reward_for()` içinde.

## Ekranlar
- **Şehir (ana ekran):** üstte coin, ortada izometrik harita, altta bina seçici + süre + Başla + Mağaza.
- **İnşaat:** iskele, yükselen bina, işçiler, geri sayım, ilerleme çubuğu, Vazgeç (onaylı).
- **Sonuç:** başarı (+coin) ya da başarısızlık mesajı. Uygulama kapalıyken biten seansın sonucu açılışta gösterilir.
- **Mağaza:** bina listesi, yetmeyen coin'de buton pasif.

## Veri modeli ve kayıt
`user://save.json` (JSON, `GameState` autoload'unda):
```
coins, inventory[bina_id], city[{id,x,y}], grid_size,
session{building,start,duration,minutes,last_seen}, stats{sessions_ok,sessions_failed,minutes}
```
Seans sırasında her 5 sn'de bir ve uygulama arka plana giderken kaydedilir; uygulama öldürülse bile açılışta `last_seen` ile değerlendirilir.

## Sonraki adımlar (öneri)
- Gerçek sanat: izometrik bina sprite'ları, animasyonlu işçi sprite'ları.
- Haritada kaydırma/yakınlaştırma ve binaları elle yerleştirme.
- İstatistik ekranı (toplam süre, seri gün sayısı), günlük hedef.
- Bildirim: seans bitince yerel bildirim (Android/iOS eklentisi gerekir).
- Android/iOS export ayarları ve mağaza yayını.
