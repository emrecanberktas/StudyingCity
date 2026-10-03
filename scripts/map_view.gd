extends Control
## Şehir haritası: GameState.city'deki binaları izometrik ızgarada çizer ve ekrana sığdırır.

const Buildings := preload("res://scripts/buildings.gd")
const Iso := preload("res://scripts/iso.gd")

const GRASS_A := Color("8cc46f")
const GRASS_B := Color("7cb36b")


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	GameState.changed.connect(queue_redraw)
	resized.connect(queue_redraw)


func _draw() -> void:
	var n := GameState.grid_size
	# Zemin n*tw/2 yüksekliğinde; en uzun bina için üstte pay bırak.
	var tw := minf(size.x * 0.94 / n, size.y / (n * 0.5 + 1.6))
	var map_h := n * tw * 0.5
	var origin := Vector2(size.x * 0.5, (size.y - map_h) * 0.5 + tw * 0.5)

	for y in n:
		for x in n:
			var c := _cell_center(origin, tw, x, y)
			draw_colored_polygon(Iso.diamond(c, tw), GRASS_A if (x + y) % 2 == 0 else GRASS_B)

	var sorted := GameState.city.duplicate()
	sorted.sort_custom(func(a, b): return int(a["x"]) + int(a["y"]) < int(b["x"]) + int(b["y"]))
	for b in sorted:
		var id: String = b["id"]
		var c := _cell_center(origin, tw, int(b["x"]), int(b["y"]))
		Iso.draw_box(self, c, tw, Buildings.height(id) * tw * 0.6, Buildings.color(id))

	if GameState.city.is_empty():
		var font := get_theme_default_font()
		var msg := "İlk binanı inşa etmek için çalışmaya başla!"
		draw_string(font, Vector2(0, size.y - 20), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Color("3d405b"))


func _cell_center(origin: Vector2, tw: float, x: int, y: int) -> Vector2:
	return origin + Vector2((x - y) * tw * 0.5, (x + y + 1) * tw * 0.25)
