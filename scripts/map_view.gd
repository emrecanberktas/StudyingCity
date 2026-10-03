extends Control
## Şehir haritası: GameState.city'deki binaları izometrik ızgarada çizer.
## Tek parmakla kaydırma, iki parmakla (ya da fare tekerleğiyle) yakınlaştırma.
## Düzenleme modunda bir binaya dokunup sonra boş bir kareye dokunarak bina taşınır.

signal edit_hint_changed(text: String)

const BuildingArt := preload("res://scripts/building_art.gd")
const Iso := preload("res://scripts/iso.gd")
const Buildings := preload("res://scripts/buildings.gd")

const GRASS_A := Color("8cc46f")
const GRASS_B := Color("7cb36b")
const MIN_ZOOM := 0.6
const MAX_ZOOM := 3.0
## Bu kadar pikselden az kayan dokunuş "tıklama" sayılır.
const TAP_SLOP := 12.0

var zoom := 1.0
var pan := Vector2.ZERO
var edit_mode := false:
	set(value):
		edit_mode = value
		selected = Vector2i(-1, -1)
		_emit_hint()
		queue_redraw()
var selected := Vector2i(-1, -1)

var _touches := {}  # parmak indeksi -> konum
var _press_pos := Vector2.ZERO
var _moved := false
var _pinch_dist := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	clip_contents = true
	GameState.changed.connect(queue_redraw)
	resized.connect(queue_redraw)


func reset_view() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	queue_redraw()


# --- Girdi ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 1:
				_press_pos = event.position
				_moved = false
			elif _touches.size() == 2:
				_pinch_dist = _touch_distance()
				_moved = true  # iki parmak varsa tıklama sayılmaz
		else:
			_touches.erase(event.index)
			if _touches.is_empty() and not _moved:
				_tap(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			var dist := _touch_distance()
			if _pinch_dist > 0.0:
				_zoom_at(_touch_center(), dist / _pinch_dist)
			_pinch_dist = dist
		else:
			_drag(event.position, event.relative)
		accept_event()
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		# Masaüstünde fare; dokunmatikten türetilen sahte fare olaylarını yok say.
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_at(event.position, 1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_at(event.position, 1.0 / 1.1)
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_press_pos = event.position
					_moved = false
				elif not _moved:
					_tap(event.position)
		accept_event()
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_drag(event.position, event.relative)
			accept_event()
	elif event is InputEventMagnifyGesture:
		_zoom_at(event.position, event.factor)
		accept_event()


func _drag(pos: Vector2, relative: Vector2) -> void:
	if not _moved and pos.distance_to(_press_pos) < TAP_SLOP:
		return
	_moved = true
	pan += relative
	_clamp_pan()
	queue_redraw()


func _zoom_at(point: Vector2, factor: float) -> void:
	var new_zoom := clampf(zoom * factor, MIN_ZOOM, MAX_ZOOM)
	var real := new_zoom / zoom
	# Parmakların altındaki nokta yerinde kalsın.
	var center := size * 0.5
	pan = (pan + center - point) * real + point - center
	zoom = new_zoom
	_clamp_pan()
	queue_redraw()


func _clamp_pan() -> void:
	var limit := size * 0.5 * zoom
	pan = pan.clamp(-limit, limit)


func _tap(pos: Vector2) -> void:
	if not edit_mode:
		return
	var cell := cell_at(pos)
	if cell.x < 0:
		return
	if selected.x < 0:
		if GameState.building_at(cell) >= 0:
			selected = cell
	elif cell == selected:
		selected = Vector2i(-1, -1)
	elif GameState.building_at(cell) >= 0:
		selected = cell
	elif GameState.move_building(selected, cell):
		selected = Vector2i(-1, -1)
	_emit_hint()
	queue_redraw()


func _emit_hint() -> void:
	if not edit_mode:
		edit_hint_changed.emit("")
	elif selected.x < 0:
		edit_hint_changed.emit("Taşımak istediğin binaya dokun.")
	else:
		edit_hint_changed.emit("Şimdi boş bir kareye dokun.")


func _touch_distance() -> float:
	var p: Array = _touches.values()
	return (p[0] as Vector2).distance_to(p[1])


func _touch_center() -> Vector2:
	var p: Array = _touches.values()
	return ((p[0] as Vector2) + (p[1] as Vector2)) * 0.5


# --- Geometri ---

## Yakınlaştırma ve kaydırmayı uygulayan dönüşüm (harita koordinatı -> ekran).
func view_transform() -> Transform2D:
	var center := size * 0.5
	return Transform2D(0.0, Vector2(zoom, zoom), 0.0, center + pan) * Transform2D(0.0, -center)


func _layout() -> Dictionary:
	var n := GameState.grid_size
	# Zemin n*tw/2 yüksekliğinde; en uzun bina için üstte pay bırak.
	var tw := minf(size.x * 0.94 / n, size.y / (n * 0.5 + 1.6))
	var map_h := n * tw * 0.5
	var origin := Vector2(size.x * 0.5, (size.y - map_h) * 0.5 + tw * 0.5)
	return {"tw": tw, "origin": origin}


func cell_center(x: int, y: int) -> Vector2:
	var l := _layout()
	var tw: float = l["tw"]
	return l["origin"] + Vector2((x - y) * tw * 0.5, (x + y + 1) * tw * 0.25)


## Ekrandaki noktanın üstündeki kare; ızgara dışındaysa (-1, -1).
func cell_at(screen_pos: Vector2) -> Vector2i:
	var l := _layout()
	var tw: float = l["tw"]
	var q: Vector2 = view_transform().affine_inverse() * screen_pos - l["origin"]
	var a := q.x / (tw * 0.5)  # x - y
	var b := q.y / (tw * 0.25) - 1.0  # x + y
	var cell := Vector2i(int(floor((a + b) * 0.5 + 0.5)), int(floor((b - a) * 0.5 + 0.5)))
	var n := GameState.grid_size
	if cell.x < 0 or cell.y < 0 or cell.x >= n or cell.y >= n:
		return Vector2i(-1, -1)
	return cell


# --- Çizim ---

func _draw() -> void:
	draw_set_transform_matrix(view_transform())
	var n := GameState.grid_size
	var tw: float = _layout()["tw"]

	for y in n:
		for x in n:
			var c := cell_center(x, y)
			var color := GRASS_A if (x + y) % 2 == 0 else GRASS_B
			if edit_mode and selected.x >= 0 and GameState.building_at(Vector2i(x, y)) < 0:
				color = color.lightened(0.25)  # taşınabilecek boş kareler
			draw_colored_polygon(Iso.diamond(c, tw), color)

	var sorted := GameState.city.duplicate()
	sorted.sort_custom(func(a, b): return int(a["x"]) + int(a["y"]) < int(b["x"]) + int(b["y"]))
	for b in sorted:
		BuildingArt.draw(self, b["id"], cell_center(int(b["x"]), int(b["y"])), tw)

	if selected.x >= 0:
		# Seçili bina, üstüne yarı saydam beyaz bir kopya çizilerek vurgulanır.
		var c := cell_center(selected.x, selected.y)
		var outline := Iso.diamond(c, tw)
		outline.append(outline[0])
		draw_polyline(outline, Color.WHITE, 3.0 / zoom)
		var index := GameState.building_at(selected)
		if index >= 0:
			var id: String = GameState.city[index]["id"]
			Iso.draw_box(self, c, tw, Buildings.height(id) * tw * 0.6, Color(1, 1, 1, 0.35), 0.74)

	draw_set_transform_matrix(Transform2D.IDENTITY)
	if GameState.city.is_empty():
		var font := get_theme_default_font()
		var msg := "İlk binanı inşa etmek için çalışmaya başla!"
		draw_string(font, Vector2(0, size.y - 20), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Color("3d405b"))
