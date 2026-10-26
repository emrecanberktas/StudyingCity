extends Control
## Ana ekran: üstte coin, ortada şehir haritası ya da inşaat alanı, altta kontrol paneli.
## Arayüz kodla kuruluyor; sahne dosyası yalnızca bu betiği taşıyor.

const Buildings := preload("res://scripts/buildings.gd")
const MapView := preload("res://scripts/map_view.gd")
const BuildSite := preload("res://scripts/build_site.gd")
const PowerSaver := preload("res://scripts/power_saver.gd")
const BuildingArt := preload("res://scripts/building_art.gd")

const DAY_NAMES := ["Paz", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt"]

const DURATIONS: Array[int] = [15, 25, 30, 45, 60, 90]
const INK := Color("3d405b")
const ACCENT := Color("e07a5f")

var _durations: Array[int] = []
var _duration_index := 0

var _coins_label: Label
var _map_view: Control
var _build_site: Control
var _idle_panel: VBoxContainer
var _session_panel: VBoxContainer
var _building_picker: OptionButton
var _duration_label: Label
var _start_button: Button
var _session_title: Label
var _timer_label: Label
var _progress_bar: ProgressBar
var _overlay: Control
var _content: Control
var _power_button: Button
var _edit_button: Button
var _map_hint: Label
var _power: Node
var _eco_screen: Control
var _eco_timer: Label
var _eco_progress: Label
var _shown_second := -1
var _shown_percent := -1.0


func _ready() -> void:
	_durations.assign(DURATIONS)
	if OS.is_debug_build():
		_durations.push_front(1)  # test için 1 dakikalık seans
	_duration_index = _durations.find(25)
	theme = _make_theme()
	_power = PowerSaver.new()
	add_child(_power)
	_power.eco_changed.connect(_on_eco_changed)
	_build_ui()
	_build_eco_screen()
	GameState.changed.connect(_refresh)
	GameState.session_finished.connect(func(_s, _id, _r): _show_pending_result())
	_refresh()
	_show_pending_result()  # uygulama kapalıyken biten seans


func _process(_delta: float) -> void:
	if not GameState.has_session():
		return
	# Arayüzü yalnızca görünen değer değişince güncelle; her kare yeniden çizim pil yer.
	var second := int(ceil(GameState.remaining()))
	if second != _shown_second:
		_shown_second = second
		var text := _format_time(second)
		_timer_label.text = text
		_eco_timer.text = text
	var percent := snappedf(GameState.progress() * 100.0, 0.5)
	if percent != _shown_percent:
		_shown_percent = percent
		_progress_bar.value = percent
		_build_site.progress = percent / 100.0
		_eco_progress.text = "%s %%%d tamamlandı" % [_build_site_name(), int(percent)]


func _input(event: InputEvent) -> void:
	var touched: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed)
	if touched and _power.poke():
		get_viewport().set_input_as_handled()  # uyandıran dokunuş düğmelere gitmesin


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _overlay != null:
		_close_overlay()


# --- Arayüz kurulumu ---

func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("a8d5e2")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	_content = margin
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 56)  # çentik / durum çubuğu payı
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var root := VBoxContainer.new()
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var title := _label("Studying City")
	title.add_theme_font_size_override("font_size", 40)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(title)
	_coins_label = _label("")
	_coins_label.add_theme_font_size_override("font_size", 34)
	top.add_child(_coins_label)

	var stage := Control.new()
	stage.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(stage)
	_map_view = MapView.new()
	_map_view.set_anchors_preset(PRESET_FULL_RECT)
	stage.add_child(_map_view)
	_build_map_controls()
	_build_site = BuildSite.new()
	_build_site.set_anchors_preset(PRESET_FULL_RECT)
	stage.add_child(_build_site)

	var panel := PanelContainer.new()
	root.add_child(panel)
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	_idle_panel = _build_idle_panel()
	stack.add_child(_idle_panel)
	_session_panel = _build_session_panel()
	stack.add_child(_session_panel)


func _build_idle_panel() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_child(_label("Ne inşa edelim?"))
	_building_picker = OptionButton.new()
	_building_picker.custom_minimum_size.y = 72
	box.add_child(_building_picker)

	box.add_child(_label("Çalışma süresi"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var minus := _button("-", _change_duration.bind(-1))
	minus.custom_minimum_size.x = 100
	row.add_child(minus)
	_duration_label = _label("")
	_duration_label.custom_minimum_size.x = 220
	_duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_duration_label.add_theme_font_size_override("font_size", 40)
	row.add_child(_duration_label)
	var plus := _button("+", _change_duration.bind(1))
	plus.custom_minimum_size.x = 100
	row.add_child(plus)
	box.add_child(row)

	_start_button = _button("Çalışmaya Başla", _on_start_pressed)
	box.add_child(_start_button)
	var row2 := HBoxContainer.new()
	var shop := _button("Mağaza", _open_shop)
	shop.size_flags_horizontal = SIZE_EXPAND_FILL
	row2.add_child(shop)
	var stats := _button("İstatistik", _open_stats)
	stats.size_flags_horizontal = SIZE_EXPAND_FILL
	row2.add_child(stats)
	box.add_child(row2)
	return box


## Haritanın üstündeki küçük düğmeler ve düzenleme ipucu.
func _build_map_controls() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(PRESET_TOP_RIGHT)
	bar.grow_horizontal = GROW_DIRECTION_BEGIN
	bar.position.y = 8
	_map_view.add_child(bar)
	_edit_button = _small_button("Düzenle", func():
		_map_view.edit_mode = not _map_view.edit_mode
		_edit_button.text = "Bitti" if _map_view.edit_mode else "Düzenle")
	bar.add_child(_edit_button)
	bar.add_child(_small_button("Ortala", _map_view.reset_view))

	_map_hint = _label("")
	_map_hint.add_theme_font_size_override("font_size", 24)
	_map_hint.set_anchors_preset(PRESET_TOP_LEFT)
	_map_hint.position = Vector2(4, 16)
	_map_view.add_child(_map_hint)
	_map_view.edit_hint_changed.connect(func(text): _map_hint.text = text)


## Eko modda gösterilen siyah ekran: yalnızca sönük bir sayaç.
func _build_eco_screen() -> void:
	_eco_screen = ColorRect.new()
	_eco_screen.color = Color.BLACK
	_eco_screen.set_anchors_preset(PRESET_FULL_RECT)
	_eco_screen.visible = false
	add_child(_eco_screen)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	_eco_screen.add_child(center)
	var box := VBoxContainer.new()
	center.add_child(box)
	var dim := Color(0.35, 0.35, 0.35)
	_eco_timer = _label("")
	_eco_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_eco_timer.add_theme_font_size_override("font_size", 120)
	_eco_timer.add_theme_color_override("font_color", dim)
	box.add_child(_eco_timer)
	_eco_progress = _label("")
	_eco_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_eco_progress.add_theme_color_override("font_color", dim)
	box.add_child(_eco_progress)
	var hint := _label("Pil tasarrufu modu. Devam etmek için dokun.")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25))
	box.add_child(hint)


func _on_eco_changed(on: bool) -> void:
	_eco_screen.visible = on
	_content.visible = not on
	if _overlay != null:
		_overlay.visible = not on


func _build_session_panel() -> VBoxContainer:
	var box := VBoxContainer.new()
	_session_title = _label("")
	_session_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_session_title)
	_timer_label = _label("00:00")
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 96)
	box.add_child(_timer_label)
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size.y = 28
	_progress_bar.show_percentage = false
	box.add_child(_progress_bar)
	var hint := _label("Uygulamadan çıkarsan işçiler işi bırakır.")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	box.add_child(hint)
	box.add_child(_button("Vazgeç", _confirm_give_up))
	return box


# --- Durum ---

func _refresh() -> void:
	_coins_label.text = "%d coin" % GameState.coins
	var active := GameState.has_session()
	_idle_panel.visible = not active
	_session_panel.visible = active
	_map_view.visible = not active
	_build_site.visible = active
	DisplayServer.screen_set_keep_on(active)
	_power.enabled = GameState.settings["power_saver"]
	_power.set_session_active(active)
	_shown_second = -1
	_shown_percent = -1.0
	if active:
		var id: String = GameState.session["building"]
		_build_site.building_id = id
		_session_title.text = "%s inşa ediliyor" % Buildings.name_of(id)
	else:
		_fill_picker()
		_duration_label.text = "%d dk" % _durations[_duration_index]


func _fill_picker() -> void:
	var previous := _selected_building()
	_building_picker.clear()
	var counts := {}
	for id in GameState.inventory:
		counts[id] = counts.get(id, 0) + 1
	for id in Buildings.ORDER:
		if counts.has(id):
			_building_picker.add_item("%s  x%d" % [Buildings.name_of(id), counts[id]])
			var index := _building_picker.item_count - 1
			_building_picker.set_item_metadata(index, id)
			if id == previous:
				_building_picker.select(index)
	var empty := counts.is_empty()
	if empty:
		_building_picker.add_item("Envanter boş, mağazadan bina al")
	_building_picker.disabled = empty
	_start_button.disabled = empty


func _selected_building() -> String:
	if _building_picker.selected < 0 or _building_picker.disabled:
		return ""
	var meta: Variant = _building_picker.get_item_metadata(_building_picker.selected)
	return meta if meta is String else ""


func _change_duration(step: int) -> void:
	_duration_index = clampi(_duration_index + step, 0, _durations.size() - 1)
	_duration_label.text = "%d dk" % _durations[_duration_index]


func _on_start_pressed() -> void:
	var id := _selected_building()
	if id != "":
		GameState.start_session(id, _durations[_duration_index])


func _confirm_give_up() -> void:
	var stay := _button("Çalışmaya devam", _close_overlay)
	var quit := _button("Vazgeç", func():
		_close_overlay()
		GameState.give_up())
	_show_overlay("Vazgeçiyor musun?", _paragraph("Bina yarım kalır ve coin kazanmazsın. Bina envanterine geri döner."), [stay, quit])


func _show_pending_result() -> void:
	var r := GameState.pop_result()
	if r.is_empty():
		return
	var building_name := Buildings.name_of(r["building"])
	if r["success"]:
		_show_overlay("Tebrikler!", _paragraph("%s tamamlandı ve şehrine eklendi.\n+%d coin" % [building_name, r["reward"]]), [_button("Şehre bak", _close_overlay)])
	else:
		_show_overlay("Seans yarıda kaldı", _paragraph("%s tamamlanamadı ve envanterine geri döndü. Yeni bir seansla tekrar inşa edebilirsin." % building_name), [_button("Tamam", _close_overlay)])


func _open_shop(message := "") -> void:
	var list := VBoxContainer.new()
	if message != "":
		list.add_child(_paragraph(message))
	for id in Buildings.ORDER:
		var row := HBoxContainer.new()
		row.add_child(_building_icon(id))
		var name_label := _label(Buildings.name_of(id))
		name_label.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(name_label)
		var buy := _button("%d coin" % Buildings.price(id), func():
			if GameState.buy(id):
				_open_shop("%s alındı! İnşa etmek için bir çalışma seansı başlat." % Buildings.name_of(id)))
		buy.custom_minimum_size.x = 180
		buy.disabled = not GameState.can_buy(id)
		row.add_child(buy)
		list.add_child(row)
	_show_overlay("Mağaza  (%d coin)" % GameState.coins, list, [_button("Kapat", _close_overlay)])


func _open_stats() -> void:
	var box := VBoxContainer.new()
	var goal := int(GameState.settings["daily_goal"])
	var today := GameState.today_minutes()

	box.add_child(_label("Bugün: %d / %d dk" % [today, goal]))
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 24
	bar.show_percentage = false
	bar.max_value = goal
	bar.value = mini(today, goal)
	box.add_child(bar)

	var goal_row := HBoxContainer.new()
	var goal_label := _label("Günlük hedef")
	goal_label.size_flags_horizontal = SIZE_EXPAND_FILL
	goal_row.add_child(goal_label)
	goal_row.add_child(_small_button("-15", _change_goal.bind(-15)))
	goal_row.add_child(_small_button("+15", _change_goal.bind(15)))
	box.add_child(goal_row)

	var streak := GameState.current_streak()
	box.add_child(_label("Seri: %d gün  (en iyi: %d)" % [streak, maxi(streak, GameState.best_streak())]))

	box.add_child(_label("Son 7 gün"))
	box.add_child(_week_chart(goal))

	var total := int(GameState.stats["minutes"])
	box.add_child(_paragraph("Toplam %d sa %d dk çalıştın. %d seans tamamlandı, %d seans yarıda kaldı." % [
		total / 60, total % 60, GameState.stats["sessions_ok"], GameState.stats["sessions_failed"]]))

	_power_button = _small_button("Pil tasarrufu: %s" % ("Açık" if GameState.settings["power_saver"] else "Kapalı"), func():
		GameState.set_setting("power_saver", not GameState.settings["power_saver"])
		_open_stats())
	box.add_child(_power_button)

	_show_overlay("İstatistik", box, [_button("Kapat", _close_overlay)])


func _change_goal(step: int) -> void:
	var goal := clampi(int(GameState.settings["daily_goal"]) + step, 15, 300)
	GameState.set_setting("daily_goal", goal)
	_open_stats()


## Son 7 günün çubuk grafiği; hedefe ulaşılan günler yeşil.
func _week_chart(goal: int) -> Control:
	var days := GameState.last_days(7)
	var chart := Control.new()
	chart.custom_minimum_size = Vector2(0, 170)
	chart.draw.connect(func():
		var font := chart.get_theme_default_font()
		var top := maxi(goal, days.max())
		var slot := chart.size.x / days.size()
		var chart_h := chart.size.y - 34.0
		var goal_y := chart_h * (1.0 - float(goal) / top)
		chart.draw_line(Vector2(0, goal_y), Vector2(chart.size.x, goal_y), Color(ACCENT, 0.6), 2.0)
		for i in days.size():
			var h := chart_h * days[i] / top
			var color := Color("81b29a") if days[i] >= goal else Color("c9c3b6")
			chart.draw_rect(Rect2(slot * i + slot * 0.2, chart_h - h, slot * 0.6, h), color)
			var weekday := GameState.weekday(GameState.now() - (days.size() - 1 - i) * 86400.0)
			chart.draw_string(font, Vector2(slot * i, chart.size.y - 6), DAY_NAMES[weekday], HORIZONTAL_ALIGNMENT_CENTER, slot, 20, INK))
	return chart


## Mağaza için küçük bina çizimi.
func _building_icon(id: String) -> Control:
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(64, 72)
	# Uzun binalar küçültülerek kutuya sığdırılır.
	var tw := minf(56.0, 62.0 / (Buildings.height(id) * 0.6 + 0.4))
	icon.draw.connect(func(): BuildingArt.draw(icon, id, Vector2(32, 64), tw))
	return icon


# --- Yardımcılar ---

func _small_button(text: String, on_pressed: Callable) -> Button:
	var b := _button(text, on_pressed)
	b.custom_minimum_size = Vector2(110, 56)
	b.add_theme_font_size_override("font_size", 22)
	return b


func _show_overlay(title: String, content: Control, buttons: Array) -> void:
	_close_overlay()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	add_child(dim)
	_overlay = dim
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 620
	center.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var heading := _label(title)
	heading.add_theme_font_size_override("font_size", 38)
	box.add_child(heading)
	box.add_child(content)
	for b in buttons:
		box.add_child(b)


func _close_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l


func _paragraph(text: String) -> Label:
	var l := _label(text)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 80
	b.pressed.connect(on_pressed)
	return b


func _build_site_name() -> String:
	return Buildings.name_of(_build_site.building_id) if _build_site.building_id != "" else ""


func _format_time(seconds: float) -> String:
	var s := int(ceil(seconds))
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
	return "%02d:%02d" % [s / 60, s % 60]


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 30

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("fdf6e3")
	panel.set_corner_radius_all(24)
	panel.set_content_margin_all(24)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_constant("separation", "VBoxContainer", 14)
	t.set_constant("separation", "HBoxContainer", 12)
	t.set_color("font_color", "Label", INK)

	var states := {"normal": ACCENT, "hover": ACCENT.lightened(0.1), "pressed": ACCENT.darkened(0.15), "disabled": Color("c9c3b6")}
	for state in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[state]
		sb.set_corner_radius_all(18)
		sb.set_content_margin_all(12)
		t.set_stylebox(state, "Button", sb)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("f5f0e6"))

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("e8e0cc")
	bar_bg.set_corner_radius_all(14)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("81b29a")
	bar_fill.set_corner_radius_all(14)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	return t
