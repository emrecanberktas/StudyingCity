extends Control
## Seans sırasındaki inşaat alanı: iskele, ilerlemeyle yükselen bina ve tuğla taşıyan işçiler.

const Buildings := preload("res://scripts/buildings.gd")
const Iso := preload("res://scripts/iso.gd")
const BuildingArt := preload("res://scripts/building_art.gd")
const WorkerArt := preload("res://scripts/worker_art.gd")

const WORKERS := 4
const BRICK := Color("b5523b")

var building_id := ""
var progress := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	# Eko modda üst düğüm gizlenir, çizim tamamen durur.
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	if building_id == "":
		return
	var tw := minf(minf(size.x * 0.55, size.y * 0.6), size.y * 0.5 / (maxf(Buildings.height(building_id), 0.4) * 0.6 + 0.35))
	var base := Vector2(size.x * 0.5, size.y * 0.62)
	var full_h := maxf(Buildings.height(building_id), 0.4) * tw * 0.6

	draw_colored_polygon(Iso.diamond(base, tw * 1.7), Color("7cb36b"))
	draw_colored_polygon(Iso.diamond(base, tw, 0.85), Color("b08d57"))

	var pile := base + Vector2(-tw * 0.7, tw * 0.22)
	for i in 3:
		Iso.draw_box(self, pile + Vector2(i * tw * 0.06 - tw * 0.06, -i * tw * 0.03), tw * 0.22, tw * 0.05, BRICK, 1.0)

	if progress > 0.005:
		BuildingArt.draw(self, building_id, base, tw, progress)
	var frame_scale := 0.42 if building_id == "tower" else 0.72
	Iso.draw_box_outline(self, base, tw, full_h, Color(1, 1, 1, 0.6), frame_scale)

	_draw_workers(base, pile, tw)


func _draw_workers(base: Vector2, pile: Vector2, tw: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var s := tw * 0.03
	var figures := []  # [ayak konumu, yön, adım, poz, görünüm] — derinlik için y'ye göre sıralanır

	# Biri binanın yanında çekiçle çalışır.
	var hammer_spot := base + Vector2(tw * 0.47, tw * 0.07)
	figures.append([hammer_spot, -1, t * 7.0, "hammer", 0])

	# Diğerleri yığından binaya tuğla taşır, boş elle geri döner.
	for i in WORKERS - 1:
		var phase := t * (0.16 + i * 0.03) + i * 0.41
		var k := 0.5 - 0.5 * cos(phase * TAU)  # 0: tuğla yığını, 1: bina
		var going := sin(phase * TAU) > 0.0
		var a := PI * (0.25 + 0.5 * float(i) / maxf(1.0, WORKERS - 2))
		var target := base + Vector2(cos(a) * tw * 0.42, sin(a) * tw * 0.22)
		var foot := pile.lerp(target, k)
		var toward := 1 if target.x >= pile.x else -1
		# Adımlar kat edilen yola bağlı: yerinde dururken bacaklar da durur.
		var step := k * pile.distance_to(target) / (s * 1.6)
		figures.append([foot, toward if going else -toward, step, "carry" if going else "walk", i + 1])

	figures.sort_custom(func(a, b): return a[0].y < b[0].y)
	for f in figures:
		WorkerArt.draw(self, f[0], s, f[1], f[2], f[3], f[4])
