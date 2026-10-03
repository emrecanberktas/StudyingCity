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

## Harita kontrolü
- Tek parmakla kaydırma, iki parmakla yakınlaştırma (0.6x–3x); masaüstünde fare tekerleği. "Ortala" görünümü sıfırlar.
- "Düzenle" modunda bir binaya, sonra boş bir kareye dokunarak bina taşınır. Yeni binalar yine otomatik olarak merkeze en yakın boş kareye konur.

## İstatistik
- Bugünkü çalışma süresi ve günlük hedef (varsayılan 60 dk, 15'er dk ayarlanır, 15–300 dk).
- Seri: art arda çalışılan gün sayısı (bugün henüz çalışılmadıysa dünden sayılır) ve en iyi seri.
- Son 7 günün çubuk grafiği; hedefe ulaşılan günler yeşil.
- Toplam süre, tamamlanan ve yarıda kalan seans sayısı. Pil tasarrufu düğmesi de bu ekranda.
- Yalnızca başarılı seansların dakikaları, seansın bittiği güne yazılır.

## Bina çizimleri
Her binanın kendine özgü çizimi var (`scripts/building_art.gd`): evde kiremit çatı, kafede çizgili tente ve kapı, parkta ağaçlar ve patika, kütüphanede sütunlar, okulda bayrak, saat kulesinde saat ve sivri çatı. İnşaat sırasında gövde ve pencereler yükselir, çatı ve süslemeler bina bitince gelir.

## İşçiler
İşçiler baretli kediler (`assets/workers/cat_*.png`, 48x48 piksel, 8 yön; Emre'nin verdiği görseller). Üç kedi yığından binaya başının üstünde tuğla taşıyıp boş geri dönüyor; yürüdükleri yöne göre 8 yönden doğru görsel seçiliyor ve yürürken hafifçe zıplıyorlar. Biri binanın yanında çekiçle vuruyor. Görseller tam sayı ölçekle ve yumuşatmasız çiziliyor, piksel sanat keskin kalıyor. Kod: `scripts/build_site.gd`.

Sonra eklenebilir: her yön için yürüme kareleri gelirse zıplama yerine gerçek yürüme animasyonu.

## Android
`export_presets.cfg` içinde Android preset'i var (paket adı `com.emrecanberktas.studyingcity`, arm64 + armv7, Gradle'sız). Debug APK, Godot'nun hazır şablonuyla derlenir ve debug anahtarıyla imzalanır; Play Store için ayrı bir release anahtarı gerekir.

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
- Gerçek sanat: çizilmiş bina ve işçi sprite'ları.
- Bildirim: seans bitince yerel bildirim (Android/iOS eklentisi gerekir).
- iOS export ve mağaza yayını (release imzalama anahtarı).
