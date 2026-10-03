extends Node
## Pil tasarrufu. Kare hızını duruma göre sınırlar ve seans sırasında ekrana bir süre
## dokunulmazsa "eko moda" geçer: ekran siyaha döner (OLED ekranlarda piksel kapanır),
## işçi animasyonu durur, oyun saniyede yalnızca birkaç kare çizer. Dokununca normale döner.

signal eco_changed(on: bool)

## Seans sırasında bu kadar saniye dokunulmazsa eko moda geçilir.
const IDLE_SEC := 15.0
## Menüde ekran zaten yalnızca değişiklik olunca çizilir (low_processor_mode).
const MENU_FPS := 60
## İşçi animasyonu için yeterli; 60 FPS'e göre GPU/CPU yükü yarıya iner.
const SESSION_FPS := 30
## Eko modda sayaç saniyede bir değiştiği için 2 FPS yeterli.
const ECO_FPS := 2

## Kullanıcı ayarı; kapalıysa eko moda hiç geçilmez (kare sınırları yine geçerli).
var enabled := true:
	set(value):
		enabled = value
		if not enabled:
			_set_eco(false)
		_apply()

var session_active := false
var eco := false
var _idle := 0.0


func _ready() -> void:
	_apply()


func _process(delta: float) -> void:
	if not (enabled and session_active) or eco:
		return
	_idle += delta
	if _idle >= IDLE_SEC:
		_set_eco(true)


## Kullanıcı ekrana dokundu: sayacı sıfırla, eko moddaysa çık.
## Eko moddan çıkıldıysa true döner; dokunuşun altındaki düğmelere gitmemesi için.
func poke() -> bool:
	_idle = 0.0
	if eco:
		_set_eco(false)
		return true
	return false


func set_session_active(on: bool) -> void:
	if session_active == on:
		return
	session_active = on
	_idle = 0.0
	if not on:
		_set_eco(false)
	_apply()


func _set_eco(on: bool) -> void:
	if eco == on:
		return
	eco = on
	_apply()
	eco_changed.emit(on)


func _apply() -> void:
	if eco:
		Engine.max_fps = ECO_FPS
	elif session_active:
		Engine.max_fps = SESSION_FPS
	else:
		Engine.max_fps = MENU_FPS
