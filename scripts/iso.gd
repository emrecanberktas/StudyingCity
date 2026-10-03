extends RefCounted
## İzometrik çizim yardımcıları. tw: karonun ekrandaki genişliği (yüksekliği tw / 2).


## Merkezi verilen eşkenar dörtgen: üst, sağ, alt, sol köşeler.
static func diamond(center: Vector2, tw: float, scale := 1.0) -> PackedVector2Array:
	var hw := tw * 0.5 * scale
	var hh := tw * 0.25 * scale
	return PackedVector2Array([
		center + Vector2(0, -hh),
		center + Vector2(hw, 0),
		center + Vector2(0, hh),
		center + Vector2(-hw, 0),
	])


## Tabanı `base` olan, `h` piksel yüksekliğinde dolu kutu.
static func draw_box(ci: CanvasItem, base: Vector2, tw: float, h: float, color: Color, scale := 0.7) -> void:
	var d := diamond(base, tw, scale)
	var up := Vector2(0, -h)
	if h > 0.5:
		ci.draw_colored_polygon(PackedVector2Array([d[3], d[2], d[2] + up, d[3] + up]), color.darkened(0.2))
		ci.draw_colored_polygon(PackedVector2Array([d[2], d[1], d[1] + up, d[2] + up]), color.darkened(0.4))
	ci.draw_colored_polygon(PackedVector2Array([d[0] + up, d[1] + up, d[2] + up, d[3] + up]), color.lightened(0.15))


## Kutunun tel çerçevesi (inşaat iskelesi için).
static func draw_box_outline(ci: CanvasItem, base: Vector2, tw: float, h: float, color: Color, scale := 0.7, width := 2.0) -> void:
	var d := diamond(base, tw, scale)
	var up := Vector2(0, -h)
	var top := PackedVector2Array([d[0] + up, d[1] + up, d[2] + up, d[3] + up, d[0] + up])
	ci.draw_polyline(top, color, width)
	for i in 4:
		ci.draw_line(d[i], d[i] + up, color, width)
	ci.draw_polyline(PackedVector2Array([d[3], d[2], d[1]]), color, width)
