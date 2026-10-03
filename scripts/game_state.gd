extends Node
## Oyunun kalıcı durumu: coin, envanter, şehir haritası ve aktif çalışma seansı.
## Seans süresi duvar saatine göre hesaplanır, yani uygulama arka plana gidince sayaç durmaz.
## Kayıt dosyası: user://save.json

signal changed
signal session_finished(success: bool, building_id: String, reward: int)

const Buildings := preload("res://scripts/buildings.gd")

const SAVE_VERSION := 1
const START_GRID := 3
const STARTING_INVENTORY: Array[String] = ["house"]
## Seans sırasında uygulamadan bu kadar saniyeden uzun çıkılırsa seans başarısız olur.
const BACKGROUND_GRACE_SEC := 15.0
const HEARTBEAT_SAVE_SEC := 10.0

var save_path := "user://save.json"
## Testler için sahte saat; negatifse gerçek saat kullanılır.
var clock_override := -1.0

var coins := 0
## Satın alınmış ama henüz inşa edilmemiş binalar.
var inventory: Array[String] = []
## Haritadaki binalar: {"id", "x", "y"}
var city: Array[Dictionary] = []
var grid_size := START_GRID
## Aktif seans: {"building", "start", "duration", "minutes", "last_seen"}; boşsa seans yok.
var session: Dictionary = {}
var stats := {"sessions_ok": 0, "sessions_failed": 0, "minutes": 0}
var settings := {"power_saver": true}

var _pending_result: Dictionary = {}
var _since_save := 0.0


func _ready() -> void:
	load_game()


func _process(delta: float) -> void:
	if not has_session():
		return
	# Uzun bir kare boşluğu uygulamanın askıya alındığını gösterir; önce onu kontrol et.
	check_gap()
	if not has_session():
		return
	session["last_seen"] = now()
	tick()
	_since_save += delta
	if has_session() and _since_save >= HEARTBEAT_SAVE_SEC:
		save_game()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			if has_session():
				session["last_seen"] = now()
				save_game()
		NOTIFICATION_APPLICATION_RESUMED:
			check_gap()
			tick()


func now() -> float:
	return clock_override if clock_override >= 0.0 else Time.get_unix_time_from_system()


func new_game() -> void:
	coins = 0
	inventory = STARTING_INVENTORY.duplicate()
	city = []
	grid_size = START_GRID
	session = {}
	stats = {"sessions_ok": 0, "sessions_failed": 0, "minutes": 0}
	settings = {"power_saver": true}
	_pending_result = {}
	changed.emit()


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	save_game()
	changed.emit()


# --- Mağaza ---

func can_buy(id: String) -> bool:
	return Buildings.exists(id) and coins >= Buildings.price(id)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	coins -= Buildings.price(id)
	inventory.append(id)
	save_game()
	changed.emit()
	return true


# --- Çalışma seansı ---

func has_session() -> bool:
	return not session.is_empty()


func start_session(building_id: String, minutes: int) -> bool:
	if has_session() or minutes <= 0 or not inventory.has(building_id):
		return false
	inventory.erase(building_id)
	var t := now()
	session = {
		"building": building_id,
		"start": t,
		"duration": minutes * 60.0,
		"minutes": minutes,
		"last_seen": t,
	}
	save_game()
	changed.emit()
	return true


func remaining() -> float:
	if not has_session():
		return 0.0
	return maxf(0.0, _session_end() - now())


func progress() -> float:
	if not has_session():
		return 0.0
	return clampf((now() - float(session["start"])) / float(session["duration"]), 0.0, 1.0)


## Süre dolduysa seansı başarıyla bitirir.
func tick() -> void:
	if has_session() and now() >= _session_end():
		_finish(true)


func give_up() -> void:
	if has_session():
		_finish(false)


## Uygulama BACKGROUND_GRACE_SEC'ten uzun süre kapalı/arka planda kaldıysa seansı bozar.
## Süre, kullanıcı ayrıldıktan kısa süre sonra zaten dolduysa seans sayılır.
func check_gap() -> void:
	if not has_session():
		return
	var last := float(session["last_seen"])
	if now() - last > BACKGROUND_GRACE_SEC and _session_end() > last + BACKGROUND_GRACE_SEC:
		_finish(false)


func reward_for(minutes: int) -> int:
	return minutes  # dakika başına 1 coin


## Bitmiş ama ekranda henüz gösterilmemiş seans sonucunu döndürür ve temizler.
func pop_result() -> Dictionary:
	var r := _pending_result
	_pending_result = {}
	return r


func _session_end() -> float:
	return float(session["start"]) + float(session["duration"])


func _finish(success: bool) -> void:
	var id: String = session["building"]
	var minutes := int(session["minutes"])
	session = {}
	var reward := 0
	if success:
		reward = reward_for(minutes)
		coins += reward
		_place(id)
		stats["sessions_ok"] += 1
		stats["minutes"] += minutes
	else:
		inventory.append(id)  # bina kaybolmaz, yeni bir seansla tekrar denenebilir
		stats["sessions_failed"] += 1
	_pending_result = {"success": success, "building": id, "reward": reward}
	save_game()
	changed.emit()
	session_finished.emit(success, id, reward)


# --- Şehir haritası ---

func _place(id: String) -> void:
	var cell := _free_cell()
	if cell.x < 0:
		grid_size += 1  # harita doldu, şehir büyüsün
		cell = _free_cell()
	city.append({"id": id, "x": cell.x, "y": cell.y})


## Merkeze en yakın boş hücre; boş hücre yoksa (-1, -1).
func _free_cell() -> Vector2i:
	var used := {}
	for b in city:
		used[Vector2i(int(b["x"]), int(b["y"]))] = true
	var best := Vector2i(-1, -1)
	var best_dist := INF
	var c := (grid_size - 1) / 2.0
	for y in grid_size:
		for x in grid_size:
			var cell := Vector2i(x, y)
			if used.has(cell):
				continue
			var d := Vector2(x - c, y - c).length_squared()
			if d < best_dist - 0.001:
				best_dist = d
				best = cell
	return best


# --- Kayıt ---

func save_game() -> void:
	_since_save = 0.0
	var data := {
		"version": SAVE_VERSION,
		"coins": coins,
		"inventory": inventory,
		"city": city,
		"grid_size": grid_size,
		"session": session,
		"stats": stats,
		"settings": settings,
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_error("Kayıt yazılamadı: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		new_game()
		save_game()
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Kayıt okunamadı, yeni oyun başlatılıyor.")
		new_game()
		save_game()
		return
	coins = int(data.get("coins", 0))
	inventory.assign(data.get("inventory", []))
	city.assign(data.get("city", []))
	grid_size = int(data.get("grid_size", START_GRID))
	session = data.get("session", {})
	stats.merge(data.get("stats", {}), true)
	settings.merge(data.get("settings", {}), true)
	# Uygulama seans sırasında kapatıldıysa burada değerlendirilir.
	check_gap()
	tick()
	changed.emit()
