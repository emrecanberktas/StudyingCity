extends SceneTree
## Pil tasarrufu testleri. Çalıştırma:
##   godot --headless --path . -s res://tests/test_power_saver.gd

const PowerSaverScript := preload("res://scripts/power_saver.gd")

var _failures := 0


func _initialize() -> void:
	var ps: Node = PowerSaverScript.new()
	ps._apply()
	_check(Engine.max_fps == ps.MENU_FPS, "menu runs at menu fps")
	ps._process(60.0)
	_check(not ps.eco, "no eco mode without a session")

	ps.set_session_active(true)
	_check(Engine.max_fps == ps.SESSION_FPS, "session capped at 30 fps")
	ps._process(10.0)
	_check(not ps.eco, "still awake after 10 s")
	ps._process(6.0)
	_check(ps.eco and Engine.max_fps == ps.ECO_FPS, "eco mode after 16 s idle, 2 fps")

	_check(ps.poke() and not ps.eco, "touch wakes it and swallows the touch")
	_check(Engine.max_fps == ps.SESSION_FPS, "back to session fps")
	_check(not ps.poke(), "normal touch passes through")

	ps._process(20.0)
	ps.set_session_active(false)
	_check(not ps.eco and Engine.max_fps == ps.MENU_FPS, "session end leaves eco mode")

	ps.enabled = false
	ps.set_session_active(true)
	ps._process(60.0)
	_check(not ps.eco and Engine.max_fps == ps.SESSION_FPS, "disabled: no eco, fps cap still on")
	ps.free()

	print("FAILURES: %d" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		_failures += 1
		printerr("  FAIL ", msg)
