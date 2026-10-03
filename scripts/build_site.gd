extends Control
## Seans sırasındaki inşaat alanı: iskele, ilerlemeyle yükselen bina ve tuğla taşıyan minik işçiler.

const Buildings := preload("res://scripts/buildings.gd")
const Iso := preload("res://scripts/iso.gd")

const WORKERS := 4
const SKIN := Color("f1c27d")
const OVERALLS := Color("3d6fb6")
const HARDHAT := Color("ffd23f")
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
	var tw := minf(size.x * 0.55, size.y * 0.6)
	var base := Vector2(size.x * 0.5, size.y * 0.62)
	var full_h := maxf(Buildings.height(building_id), 0.4) * tw * 0.6

	draw_colored_polygon(Iso.diamond(base, tw * 1.7), Color("7cb36b"))
	draw_colored_polygon(Iso.diamond(base, tw, 0.85), Color("b08d57"))

	var pile := base + Vector2(-tw * 0.7, tw * 0.22)
	for i in 3:
		Iso.draw_box(self, pile + Vector2(i * tw * 0.06 - tw * 0.06, -i * tw * 0.03), tw * 0.22, tw * 0.05, BRICK, 1.0)

	if progress > 0.005:
		Iso.draw_box(self, base, tw, full_h * progress, Buildings.color(building_id))
	Iso.draw_box_outline(self, base, tw, full_h, Color(1, 1, 1, 0.6))

	_draw_workers(base, pile, tw)


func _draw_workers(base: Vector2, pile: Vector2, tw: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var s := tw * 0.035
	for i in WORKERS:
		var phase := t * (0.22 + i * 0.05) + i * 0.37
		var k := 0.5 - 0.5 * cos(phase * TAU)  # 0: tuğla yığını, 1: bina
		var going := sin(phase * TAU) > 0.0
		var a := PI * (0.2 + 0.6 * float(i) / (WORKERS - 1))
		var target := base + Vector2(cos(a) * tw * 0.42, sin(a) * tw * 0.22)
		var p := pile.lerp(target, k) + Vector2(0, -absf(sin(t * 9.0 + i)) * s * 0.8)
		# gövde, kafa, baret
		draw_rect(Rect2(p + Vector2(-s * 0.6, -s * 2.2), Vector2(s * 1.2, s * 2.0)), OVERALLS)
		draw_circle(p + Vector2(0, -s * 2.8), s * 0.7, SKIN)
		draw_circle(p + Vector2(0, -s * 3.2), s * 0.6, HARDHAT)
		if going:
			draw_rect(Rect2(p + Vector2(-s * 0.8, -s * 4.6), Vector2(s * 1.6, s * 0.7)), BRICK)
