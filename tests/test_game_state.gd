extends SceneTree
## Oyun mantığı testleri. Çalıştırma:
##   godot --headless --path . -s res://tests/test_game_state.gd

const GameStateScript := preload("res://scripts/game_state.gd")

var _failures := 0


func _initialize() -> void:
	_test_full_session()
	_test_give_up_returns_building()
	_test_background_too_long_fails()
	_test_short_background_is_ok()
	_test_finished_while_away_counts()
	_test_shop()
	_test_city_grows()
	_test_save_roundtrip()
	print("FAILURES: %d" % _failures)
	quit(1 if _failures > 0 else 0)


func _fresh() -> Node:
	var gs: Node = GameStateScript.new()
	gs.save_path = "user://test_save.json"
	gs.clock_override = 1000.0
	gs.new_game()
	return gs


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		_failures += 1
		printerr("  FAIL ", msg)


func _test_full_session() -> void:
	print("full session")
	var gs := _fresh()
	_check(gs.start_session("house", 25), "starts with starting house")
	_check(gs.inventory.is_empty(), "house leaves inventory while building")
	gs.clock_override += 10 * 60
	gs.session["last_seen"] = gs.now()
	gs.tick()
	_check(gs.has_session() and absf(gs.progress() - 0.4) < 0.001, "progress 40% after 10 min")
	gs.clock_override += 15 * 60
	gs.session["last_seen"] = gs.now()
	gs.tick()
	_check(not gs.has_session(), "session finished")
	_check(gs.coins == 25, "earned 25 coins")
	_check(gs.city.size() == 1 and gs.city[0]["x"] == 1 and gs.city[0]["y"] == 1, "house placed at center")
	var r: Dictionary = gs.pop_result()
	_check(r.get("success") == true and gs.pop_result().is_empty(), "result popped once")
	gs.free()


func _test_give_up_returns_building() -> void:
	print("give up")
	var gs := _fresh()
	gs.start_session("house", 25)
	gs.give_up()
	_check(gs.coins == 0 and gs.city.is_empty(), "no reward, nothing placed")
	_check(gs.inventory == ["house"], "house back in inventory")
	gs.free()


func _test_background_too_long_fails() -> void:
	print("background too long")
	var gs := _fresh()
	gs.start_session("house", 25)
	gs.clock_override += 60
	gs.check_gap()
	_check(not gs.has_session() and gs.coins == 0, "60 s away fails the session")
	gs.free()


func _test_short_background_is_ok() -> void:
	print("short background")
	var gs := _fresh()
	gs.start_session("house", 25)
	gs.clock_override += 5
	gs.check_gap()
	_check(gs.has_session(), "5 s away keeps the session")
	gs.free()


func _test_finished_while_away_counts() -> void:
	print("finished while away")
	var gs := _fresh()
	gs.start_session("house", 1)
	gs.clock_override += 55
	gs.session["last_seen"] = gs.now()
	gs.clock_override += 3600  # app left 5 s before the end, came back an hour later
	gs.check_gap()
	gs.tick()
	_check(gs.coins == 1 and gs.city.size() == 1, "session counts as done")
	gs.free()


func _test_shop() -> void:
	print("shop")
	var gs := _fresh()
	_check(not gs.buy("house"), "cannot buy without coins")
	gs.coins = 40
	_check(gs.buy("cafe") and gs.coins == 10, "buy cafe for 30")
	_check(gs.inventory.has("cafe"), "cafe in inventory")
	_check(not gs.buy("nope"), "unknown building rejected")
	gs.free()


func _test_city_grows() -> void:
	print("city grows")
	var gs := _fresh()
	for i in 10:
		gs.inventory.append("house")
		gs.start_session("house", 1)
		gs.clock_override += 61
		gs.session["last_seen"] = gs.now() - 1
		gs.tick()
	_check(gs.city.size() == 10, "10 buildings placed")
	_check(gs.grid_size == 4, "grid grew from 3x3 to 4x4")
	var cells := {}
	for b in gs.city:
		cells[Vector2i(b["x"], b["y"])] = true
	_check(cells.size() == 10, "no two buildings share a cell")
	gs.free()


func _test_save_roundtrip() -> void:
	print("save/load")
	var gs := _fresh()
	gs.coins = 77
	gs.start_session("house", 30)
	gs.save_game()
	var gs2 := _fresh()
	gs2.clock_override = gs.clock_override + 2
	gs2.load_game()
	_check(gs2.coins == 77 and gs2.has_session(), "coins and running session restored")
	gs2.clock_override += 3600
	gs2.load_game()  # app killed for an hour
	_check(not gs2.has_session() and gs2.inventory.has("house"), "session killed by long absence fails on load")
	gs.free()
	gs2.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.json"))
