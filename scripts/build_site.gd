extends Control
## Seans sırasındaki inşaat alanı: iskele, ilerlemeyle yükselen bina ve tuğla taşıyan kedi işçiler.

const Buildings := preload("res://scripts/buildings.gd")
const Iso := preload("res://scripts/iso.gd")
const BuildingArt := preload("res://scripts/building_art.gd")

const WORKERS := 4
const BRICK := Color("b5523b")
const HANDLE := Color("8a5a2b")
const HAMMER_HEAD := Color("6b6b6b")
## Kedi işçi görselleri, 48x48 piksel; sıra _direction() ile aynı (doğudan saat yönünde).
const CAT_TEXTURES: Array[Texture2D] = [
	preload("res://assets/workers/cat_east.png"),
	preload("res://assets/workers/cat_south_east.png"),
	preload("res://assets/workers/cat_south.png"),
	preload("res://assets/workers/cat_south_west.png"),
	preload("res://assets/workers/cat_west.png"),
	preload("res://assets/workers/cat_north_west.png"),
	preload("res://assets/workers/cat_north.png"),
	preload("res://assets/workers/cat_north_east.png"),
]
const CAT_SIZE := 48.0
## Görselde ayakların ortası (piksel).
const CAT_FOOT := Vector2(24, 47)

var building_id := ""
var progress := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	texture_filter = TEXTURE_FILTER_NEAREST  # piksel sanat keskin kalsın


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
	# Piksel sanat bozulmasın diye tam sayı ölçek.
	var scale := maxf(1.0, round(tw * 0.28 / CAT_SIZE))
	var figures := []  # [ayak konumu, yön indeksi, zıplama, tuğla taşıyor mu, çekiç açısı]

	# Biri binanın yanında çekiçle çalışır.
	var swing := sin(t * 7.0) * 0.5 + 0.5  # 0: kalkık, 1: vuruş
	figures.append([base + Vector2(tw * 0.5, tw * 0.08), _direction(Vector2.LEFT), 0.0, false, swing])

	# Diğerleri yığından binaya tuğla taşır, boş elle geri döner.
	for i in WORKERS - 1:
		var phase := t * (0.16 + i * 0.03) + i * 0.41
		var k := 0.5 - 0.5 * cos(phase * TAU)  # 0: tuğla yığını, 1: bina
		var going := sin(phase * TAU) > 0.0
		var a := PI * (0.25 + 0.5 * float(i) / maxf(1.0, WORKERS - 2))
		var target := base + Vector2(cos(a) * tw * 0.42, sin(a) * tw * 0.22)
		var heading := (target - pile) if going else (pile - target)
		# Yürürken hafifçe zıplar; uçlarda (durunca) zıplama biter.
		var speed := absf(sin(phase * TAU))
		var hop := absf(sin(k * pile.distance_to(target) / (tw * 0.05))) * speed * scale * 3.0
		figures.append([pile.lerp(target, k), _direction(heading), hop, going, -1.0])

	figures.sort_custom(func(a, b): return a[0].y < b[0].y)
	for f in figures:
		_draw_cat(f[0], f[1], f[2], f[3], f[4], scale)


## Ekrandaki hareket yönünü 8 yönden birine çevirir (0 doğu, saat yönünde).
func _direction(v: Vector2) -> int:
	return posmod(int(round(v.angle() / (PI / 4.0))), 8)


func _draw_cat(foot: Vector2, dir: int, hop: float, carrying: bool, hammer: float, scale: float) -> void:
	var tex: Texture2D = CAT_TEXTURES[dir]
	var size := Vector2(CAT_SIZE, CAT_SIZE) * scale
	# Gölge zıplarken küçülür.
	var shadow := 1.0 - clampf(hop / (scale * 6.0), 0.0, 0.4)
	draw_set_transform(foot, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, CAT_SIZE * 0.3 * scale * shadow, Color(0, 0, 0, 0.2))
	draw_set_transform_matrix(Transform2D.IDENTITY)

	var top_left := foot - Vector2(CAT_FOOT.x, CAT_FOOT.y + hop / scale) * scale
	draw_texture_rect(tex, Rect2(top_left, size), false)

	if carrying:
		# Başının üstünde tuğla
		var brick := Rect2(top_left + Vector2(14, -3) * scale, Vector2(20, 7) * scale)
		draw_rect(brick, BRICK)
		draw_rect(Rect2(brick.position + Vector2(0, 3) * scale, Vector2(brick.size.x, scale)), BRICK.darkened(0.3))
	if hammer >= 0.0:
		# Pençesinden binaya doğru inen çekiç
		var pivot := top_left + Vector2(14, 28) * scale
		var dir_v := Vector2.from_angle(lerpf(-1.7, -3.4, hammer))  # yukarıdan sola, binaya doğru
		var tip := pivot + dir_v * 14.0 * scale
		draw_line(pivot, tip, HANDLE, 2.0 * scale)
		var head := dir_v.orthogonal() * 4.0 * scale
		draw_line(tip - head, tip + head, HAMMER_HEAD, 4.0 * scale)
