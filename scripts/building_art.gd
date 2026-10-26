extends RefCounted
## Binaların çizimi: her binanın kendine özgü gövdesi, pencereleri ve çatısı var.
## Hem şehir haritası hem de inşaat alanı bunu kullanır.

const Buildings := preload("res://scripts/buildings.gd")
const Iso := preload("res://scripts/iso.gd")

const WINDOW := Color("fff3c4")
const WINDOW_DARK := Color("2f3b52")
const ROOF := Color("8f3b2e")
const TREE := Color("3f8f4f")
const TRUNK := Color("7a4f2a")


## `build` 0..1 arası inşaat ilerlemesi; 1'den küçükken çatı ve süslemeler çizilmez.
static func draw(ci: CanvasItem, id: String, base: Vector2, tw: float, build := 1.0) -> void:
	var color := Buildings.color(id)
	var full_h := Buildings.height(id) * tw * 0.6
	var done := build >= 0.999
	match id:
		"park":
			_park(ci, base, tw, color, done)
		"tower":
			var h := full_h * build
			Iso.draw_box(ci, base, tw, h, color, 0.42)
			if h > tw * 0.1:
				_windows(ci, base, tw, 0.42, h, 1, int(h / (tw * 0.22)), WINDOW_DARK)
			if done:
				_tower_top(ci, base, tw, h, color)
		_:
			var scale := 0.72 if id != "library" else 0.8
			var h := maxf(full_h * build, 1.0)
			Iso.draw_box(ci, base, tw, h, color, scale)
			var cols := 2 if id == "house" else 3
			var rows := maxi(1, int(h / (tw * 0.2)))
			if id == "library":
				_columns(ci, base, tw, scale, h)
			elif h > tw * 0.08:
				_windows(ci, base, tw, scale, h, cols, rows, WINDOW)
			if done:
				match id:
					"house":
						_pyramid_roof(ci, base, tw, scale, h, ROOF, tw * 0.3)
					"cafe":
						_awning(ci, base, tw, scale, h)
					"library":
						_pyramid_roof(ci, base, tw, scale, h, color.lightened(0.35), tw * 0.14)
					"school":
						_flag(ci, base, tw, h)


## Yüz üzerindeki bir dörtgen. face 0: sol yüz, 1: sağ yüz.
## s: yüz boyunca 0..1, t: yerden piksel yükseklik.
static func face_quad(base: Vector2, tw: float, scale: float, face: int, s0: float, s1: float, t0: float, t1: float) -> PackedVector2Array:
	var d := Iso.diamond(base, tw, scale)
	var a: Vector2 = d[3] if face == 0 else d[2]
	var b: Vector2 = d[2] if face == 0 else d[1]
	return PackedVector2Array([
		a.lerp(b, s0) + Vector2(0, -t0),
		a.lerp(b, s1) + Vector2(0, -t0),
		a.lerp(b, s1) + Vector2(0, -t1),
		a.lerp(b, s0) + Vector2(0, -t1),
	])


static func _windows(ci: CanvasItem, base: Vector2, tw: float, scale: float, h: float, cols: int, rows: int, color: Color) -> void:
	var row_h := h / (rows + 0.3)
	for face in 2:
		var shade := color if face == 0 else color.darkened(0.25)
		for r in rows:
			var t0 := row_h * (r + 0.35)
			var t1 := t0 + row_h * 0.5
			for c in cols:
				var s0 := (c + 0.3) / cols
				ci.draw_colored_polygon(face_quad(base, tw, scale, face, s0, s0 + 0.4 / cols, t0, t1), shade)


static func _columns(ci: CanvasItem, base: Vector2, tw: float, scale: float, h: float) -> void:
	for face in 2:
		for c in 4:
			var s0 := (c + 0.35) / 4.0
			ci.draw_colored_polygon(face_quad(base, tw, scale, face, s0, s0 + 0.08, h * 0.08, h * 0.85), Color(1, 1, 1, 0.55))


static func _pyramid_roof(ci: CanvasItem, base: Vector2, tw: float, scale: float, h: float, color: Color, rise: float) -> void:
	var d := Iso.diamond(base + Vector2(0, -h), tw, scale * 1.08)
	var apex := base + Vector2(0, -h - rise)
	ci.draw_colored_polygon(PackedVector2Array([d[3], d[0], apex]), color.lightened(0.1))
	ci.draw_colored_polygon(PackedVector2Array([d[0], d[1], apex]), color)
	ci.draw_colored_polygon(PackedVector2Array([d[3], d[2], apex]), color.darkened(0.1))
	ci.draw_colored_polygon(PackedVector2Array([d[2], d[1], apex]), color.darkened(0.3))


static func _awning(ci: CanvasItem, base: Vector2, tw: float, scale: float, h: float) -> void:
	# Sağ yüzde, kapının üstünde çizgili tente.
	var stripes := 5
	for i in stripes:
		var s0 := 0.1 + 0.8 * i / stripes
		var s1 := 0.1 + 0.8 * (i + 1) / stripes
		var q := face_quad(base, tw, scale, 1, s0, s1, h * 0.45, h * 0.6)
		q[0] += Vector2(tw * 0.05, tw * 0.03)
		q[1] += Vector2(tw * 0.05, tw * 0.03)
		ci.draw_colored_polygon(q, Color("d64545") if i % 2 == 0 else Color.WHITE)
	ci.draw_colored_polygon(face_quad(base, tw, scale, 1, 0.4, 0.6, 0, h * 0.4), Color("6b4226"))


static func _flag(ci: CanvasItem, base: Vector2, tw: float, h: float) -> void:
	var foot := base + Vector2(0, -h)
	var top := foot + Vector2(0, -tw * 0.35)
	ci.draw_line(foot, top, Color("555555"), maxf(1.5, tw * 0.015))
	ci.draw_colored_polygon(PackedVector2Array([top, top + Vector2(tw * 0.16, tw * 0.04), top + Vector2(0, tw * 0.09)]), Color("d64545"))


static func _tower_top(ci: CanvasItem, base: Vector2, tw: float, h: float, color: Color) -> void:
	# Sağ yüzde saat, üstte sivri kule.
	var q := face_quad(base, tw, 0.42, 1, 0.5, 0.5, h * 0.8, h * 0.8)
	ci.draw_circle(q[0], tw * 0.07, Color.WHITE)
	ci.draw_line(q[0], q[0] + Vector2(0, -tw * 0.05), Color("333333"), 2.0)
	ci.draw_line(q[0], q[0] + Vector2(tw * 0.035, 0), Color("333333"), 2.0)
	_pyramid_roof(ci, base, tw, 0.42, h, ROOF, tw * 0.45)


static func _park(ci: CanvasItem, base: Vector2, tw: float, color: Color, done: bool) -> void:
	ci.draw_colored_polygon(Iso.diamond(base, tw, 0.9), color.lightened(0.1))
	# Ortadan geçen patika
	var d := Iso.diamond(base, tw, 0.9)
	ci.draw_line(d[3].lerp(d[0], 0.5), d[2].lerp(d[1], 0.5), Color("e9dcc0"), maxf(2.0, tw * 0.05))
	if not done:
		return
	var spots := [Vector2(-0.18, -0.02), Vector2(0.15, -0.06), Vector2(0.02, 0.1)]
	for p in spots:
		var foot: Vector2 = base + Vector2(p.x * tw, p.y * tw)
		ci.draw_line(foot, foot + Vector2(0, -tw * 0.12), TRUNK, maxf(2.0, tw * 0.03))
		ci.draw_circle(foot + Vector2(0, -tw * 0.17), tw * 0.08, TREE)
		ci.draw_circle(foot + Vector2(-tw * 0.025, -tw * 0.19), tw * 0.04, TREE.lightened(0.2))
